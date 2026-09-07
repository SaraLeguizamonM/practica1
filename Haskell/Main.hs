module Main where

import qualified Data.ByteString as B
import Data.Char (isSpace)
import Data.Word (Word8)
import Data.Bits (testBit)

type Ancho = Int
type Alto = Int
type Altura = Int
type VectorAlturas = [Altura]

parsePBM :: B.ByteString -> (Ancho, Alto, B.ByteString)
parsePBM bs =
    let tokens = extractTokens bs
        ancho = read (tokens !! 1) :: Int
        alto  = read (tokens !! 2) :: Int
        datosBinarios = dropHeader bs
    in (ancho, alto, datosBinarios)

extractTokens :: B.ByteString -> [String]
extractTokens bs = 
    let texto = map (toEnum . fromIntegral) (B.unpack bs) :: String
        lineasSinComentarios = filter (not . esComentario) (lines texto)
    in concatMap words lineasSinComentarios

esComentario :: String -> Bool
esComentario line = case dropWhile isSpace line of
                      ('#':_) -> True
                      _       -> False

dropHeader :: B.ByteString -> B.ByteString
dropHeader bs = go 0 0 bs
  where
    go :: Int -> Int -> B.ByteString -> B.ByteString
    go lineCount tokenCount rest
      | B.null rest = B.empty
      | tokenCount >= 3 = rest
      | otherwise =
          let (line, remainder) = B.break (== 10) rest -- 10 es '\n' en ASCII
              nextRest = if B.null remainder then B.empty else B.tail remainder
              lineStr = map (toEnum . fromIntegral) (B.unpack line) :: String
          in if esComentario lineStr || null (words lineStr)
             then go (lineCount + 1) tokenCount nextRest
             else go (lineCount + 1) (tokenCount + length (words lineStr)) nextRest

pixelEn :: Ancho -> B.ByteString -> Int -> Int -> Bool
pixelEn ancho bytes x y =
    let bytesPorFila = (ancho + 7) `div` 8
        byteIndex    = y * bytesPorFila + (x `div` 8)
        bitIndex     = 7 - (x `mod` 8)
        byteVal      = B.index bytes byteIndex
    in testBit byteVal bitIndex

extraerAlturas :: Ancho -> Alto -> B.ByteString -> VectorAlturas
extraerAlturas ancho alto bytes = [ buscarAlturaEnColumna x | x <- [0 .. ancho - 1] ]
  where
    buscarAlturaEnColumna :: Int -> Altura
    buscarAlturaEnColumna x =
      let filasDesdeAbajo = [alto - 1, alto - 2 .. 0]
          esNegro y = pixelEn ancho bytes x y
          pixelesConsecutivos = takeWhile esNegro filasDesdeAbajo
      in length pixelesConsecutivos

calcularArea :: VectorAlturas -> Int
calcularArea = sum


mostrarMuestras :: VectorAlturas -> IO ()
mostrarMuestras alturas = do
  let total = length alturas
      indices = [0, 62, 125, 188, 251, 314, 377, 440, 503, total - 1]
      muestras = [(i, alturas !! i) | i <- indices, i < total]
  putStrLn "\nALGUNOS VALORES x_i -> f(x_i)"
  mapM_ (\(x, y) -> putStrLn $ "x_" ++ show x ++ " = " ++ show x ++ "  ->  f(x_" ++ show x ++ ") = " ++ show y ++ " pixeles") muestras

dibujarCurvaConsola :: VectorAlturas -> Int -> IO ()
dibujarCurvaConsola alturas altoOriginal = do
  let anchoOriginal = length alturas
      anchoConsola = 80 
      altoConsola  = 20 

      factorX = fromIntegral anchoOriginal / fromIntegral anchoConsola :: Double
      alturasReducidas = [ alturas !! floor (fromIntegral i * factorX) | i <- [0 .. anchoConsola - 1] ]

      escalaY h = floor ((fromIntegral h / fromIntegral altoOriginal) * fromIntegral altoConsola) :: Int

      construirFila y = [ if escalaY h >= y then '█' else ' ' | h <- alturasReducidas ]

      filas = [ construirFila y | y <- [altoConsola, altoConsola - 1 .. 0] ]

  putStrLn "\nREPRESENTACIÓN DE LA CURVA EN CONSOLA"
  putStrLn (replicate anchoConsola '-')
  mapM_ putStrLn filas
  putStrLn (replicate anchoConsola '-')

formatearAlturas :: VectorAlturas -> String
formatearAlturas alturas = unlines (map show alturas)

main :: IO ()
main = do
    let nombreArchivoEntrada = "curva_binaria_P4.pbm"
    let nombreArchivoSalida  = "alturas.txt"
    
    contenido <- B.readFile nombreArchivoEntrada
    let (ancho, alto, bytesDatos) = parsePBM contenido
    let alturas = extraerAlturas ancho alto bytesDatos
    let area = calcularArea alturas
    
    putStrLn $ "Imagen: " ++ show ancho ++ " x " ++ show alto ++ " pixeles"
    putStrLn $ "Area: " ++ show area ++ " pixeles cuadrados"
    
    dibujarCurvaConsola alturas alto
    mostrarMuestras alturas
    
    writeFile nombreArchivoSalida (formatearAlturas alturas)
    putStrLn $ "\nVector M[x] guardado en '" ++ nombreArchivoSalida ++ "'."