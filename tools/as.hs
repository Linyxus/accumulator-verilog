#!/usr/bin/env stack
-- stack --resolver lts-13.17 script
{-# LANGUAGE OverloadedStrings #-}
import qualified Options.Applicative as Opt
import Options.Applicative hiding (Parser, execParser, some, many)
import Data.Text (Text)
import qualified Data.Text.IO as TIO
import Text.Megaparsec hiding (option)
import Text.Megaparsec.Char
import Data.Void
import Data.List (intercalate)
import qualified Data.Map as M
import Control.Monad.Except

type Parser = Parsec Void Text

data Op = Nop
        | Add
        | Addi
        | Load
        | Store
        | Jumpi
        | Loadi
        | Value
        deriving (Eq, Show)

pOp :: Parser Op
pOp = symbol $ choice [ Nop <$ string "nop"
                      , try $ Addi <$ string "addi"
                      , Add <$ string "add"
                      , try $ Loadi <$ string "loadi"
                      , Load <$ string "load"
                      , Store <$ string "store"
                      , Jumpi <$ string "jumpi"
                      , Value <$ string "value"
                      ]

type ImmVal = Int

symbol :: Parser a -> Parser a
symbol = (<* (space1 <|> eof))

pImmVal :: Parser ImmVal
pImmVal = symbol $ char '$' >> read <$> some digitChar

data Addr = AVal Int
          | ALabel String
          deriving (Eq, Show)

pIdent :: Parser String
pIdent = char '.' >> (:) <$> lowerChar <*> many alphaNumChar

pAddr :: Parser Addr
pAddr = symbol $ choice [ AVal . read <$> some digitChar
                        , ALabel <$> pIdent 
                        ]

data Inst = INop
          | IAdd Addr
          | IAddI ImmVal
          | ILoad Addr
          | IStore Addr
          | IJumpI Addr
          | ILoadI ImmVal
          | IValue ImmVal
          deriving (Eq, Show)

data TagInst = NoTag Inst
             | Tag String Inst
             deriving (Eq, Show)

pTag :: Parser String
pTag = symbol $ char '.' >> (:) <$> lowerChar <*> many alphaNumChar

pInst :: Parser Inst
pInst = pOp >>= f
    where f Nop = return INop
          f Add = IAdd <$> pAddr
          f Addi = IAddI <$> pImmVal
          f Load = ILoad <$> pAddr
          f Store = IStore <$> pAddr
          f Jumpi = IJumpI <$> pAddr
          f Loadi = ILoadI <$> pImmVal
          f Value = IValue <$> pImmVal

pTagInst :: Parser TagInst
pTagInst = fmap f $ (,) <$> optional pTag <*> pInst
    where f (Nothing, i) = NoTag i
          f (Just t, i) = Tag t i

data AppConfig = AppConfig
    { srcPath :: String
    , outputPath :: String
    , fixedLength :: Bool
    , codeLength :: Int
    } deriving (Eq, Show)

configP :: Opt.Parser AppConfig
configP = AppConfig <$> srcOpt <*> outputOpt <*> fixedOpt <*> lenOpt
    where srcOpt = strOption $ long "source"
                            <> short 's'
                            <> metavar "SOURCE"
                            <> help "Source file path"
          outputOpt = strOption $ long "output"
                               <> short 'o'
                               <> metavar "OUTPUT"
                               <> help "Output file path"
          fixedOpt = switch $ long "fixed-length"
                           <> short 'f'
                           <> help "Whether to generate fixed-length machine code"
          lenOpt = option auto $ long "code-length"
                              <> short 'l'
                              <> showDefault
                              <> value 32
                              <> metavar "INT"
                              <> help "Fixed machine code length, ignored when fixed-length is not turned on"

data AppError = ParseError String
              | DuplicateTag String
              | UndefinedTag String
              | OverLong Int Int
              deriving (Eq)

showError :: String -> String -> String
showError p s = "[" ++ p ++ "]\n" ++ s

showAppError :: AppError -> String
showAppError (ParseError e) = showError "Parse Error" e
showAppError (DuplicateTag s) = showError "Compile Error" $ "Found duplicate Tag: " ++ s
showAppError (UndefinedTag s) = showError "Compile Error" $ "Tag " ++ s ++ " is not found"
showAppError (OverLong n l) = showError "Compile Error" $ "Code overlong: " ++ show l ++ ", max is "
                                                        ++ show n

instance Show AppError where show = showAppError

type App = ExceptT AppError IO

runApp :: App a -> IO ()
runApp = (>>= f) . runExceptT
    where f (Left e) = print e
          f (Right _) = return ()

parseFile :: String -> App [TagInst]
parseFile src = liftIO (parse (many pTagInst) src <$> TIO.readFile src) >>= f
    where f :: Either (ParseErrorBundle Text Void) [TagInst] -> App [TagInst]
          f mx = case mx of
                     Left bundle -> throwError $ ParseError $ errorBundlePretty bundle
                     Right xs -> return xs

parseOpt :: App AppConfig
parseOpt = liftIO $ Opt.execParser opts
    where opts = info (configP <**> helper) $ fullDesc
                                          <> progDesc "Assemble the source file into a text format compatible with $readmemb in Verilog"
                                          <> header "as - A Simple Assembler"

buildTags :: [TagInst] -> App (M.Map String Int)
buildTags = go 0
    where go _ [] = return M.empty
          go n (NoTag _:xs) = go (n+1) xs
          go n (Tag t i:xs) = go (n+1) xs >>= f t n
          f :: String -> Int -> M.Map String Int -> App (M.Map String Int)
          f t n m
            | M.member t m = throwError $ DuplicateTag t
            | otherwise = return $ M.insert t n m

int2bin :: Int -> String
int2bin = reverse . go
    where go 0 = "0"
          go n | n `mod` 2 == 0 = '0' : go (n `div` 2)
               | otherwise = '1' : go (n `div` 2)

int2bin' :: Int -> Int -> String
int2bin' n i | len >= n = drop (len - n) bstr | otherwise = replicate (n-len) '0' ++ bstr
    where bstr = int2bin i
          len = length bstr

type TagTable = M.Map String Int

mkInst :: TagTable -> Inst -> App String
mkInst _ INop = mkNop
mkInst m (IAdd a) = mkAdd m a
mkInst m (ILoad a) = mkLoad m a
mkInst m (IStore a) = mkStore m a
mkInst m (IJumpI a) = mkJumpI m a
mkInst _ (IAddI v) = mkAddI v
mkInst _ (ILoadI v) = mkLoadI v
mkInst _ (IValue v) = return $ mkImm8 v

mkNop :: App String
mkNop = return $ int2bin' 8 0

mkAddrInst :: String -> TagTable -> Addr -> App String
mkAddrInst pref m a = (pref ++) <$> mkAddr m a

mkImmInst :: String -> ImmVal -> App String
mkImmInst p v = return $ p ++ mkImm v

mkLoadI :: ImmVal -> App String
mkLoadI = mkImmInst "0001"

mkAdd :: TagTable -> Addr -> App String
mkAdd = mkAddrInst "100"

mkAddI :: ImmVal -> App String
mkAddI = mkImmInst "0010"

mkLoad :: TagTable -> Addr -> App String
mkLoad = mkAddrInst "101"

mkStore :: TagTable -> Addr -> App String
mkStore = mkAddrInst "110"

mkJumpI :: TagTable -> Addr -> App String
mkJumpI = mkAddrInst "111"

mkImm :: ImmVal -> String
mkImm = int2bin' 4

mkImm8 :: ImmVal -> String
mkImm8 = int2bin' 8

mkAddr :: TagTable -> Addr -> App String
mkAddr _ (AVal n) = return $ int2bin' 5 n
mkAddr m (ALabel t) = case M.lookup t m of
                          Nothing -> throwError $ UndefinedTag t
                          Just n -> return $ int2bin' 5 n

mkTagInst :: TagTable -> TagInst -> App String
mkTagInst m (Tag _ i) = mkInst m i
mkTagInst m (NoTag i) = mkInst m i

padCode :: Bool -> Int -> [String] -> App [String]
padCode False _ code = return code
padCode True n codes | len > n = throwError $ OverLong n len
                     | otherwise = return $ codes ++ replicate (n - len) "00000000"
    where len = length codes

main :: IO ()
main = runApp $ do
    (AppConfig src dest f l) <- parseOpt
    insts <- parseFile src
    tags <- buildTags insts
    codes <- mapM (mkTagInst tags) insts >>= padCode f l
    let code = intercalate "\n" codes
    liftIO $ writeFile dest code
