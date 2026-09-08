-- Módulo principal para análisis de imágenes PBM binarias (P4).
-- Lee la cabecera del archivo, procesa el mapa de bits a nivel de byte para
-- calcular la función de altura f(x) y exporta los resultados.
module Main where

-- Módulos para manipulación eficiente de datos binarios y operaciones a nivel de bit
import qualified Data.ByteString as B
import Data.Char (isSpace)
import Data.Word (Word8)
import Data.Bits (testBit)

-- Alias de tipos para mejorar la legibilidad y semántica del dominio del problema
type Ancho = Int
type Alto = Int
type Altura = Int
type VectorAlturas = [Altura]

-- Función principal de parsing del archivo PBM binario.
-- Separa las dimensiones (ancho, alto) de los datos binarios puros del mapa de bits.
parsePBM :: B.ByteString -> (Ancho, Alto, B.ByteString)
parsePBM bs =
    let tokens = extractTokens bs
        ancho = read (tokens !! 1) :: Int
        alto  = read (tokens !! 2) :: Int
        datosBinarios = dropHeader bs
    in (ancho, alto, datosBinarios)

-- Extrae los tokens de texto de la cabecera PBM, ignorando comentarios '#'.
-- Convierte únicamente la cabecera legible a cadenas de texto para su lectura.
extractTokens :: B.ByteString -> [String]
extractTokens bs = 
    let texto = map (toEnum . fromIntegral) (B.unpack bs) :: String
        lineasSinComentarios = filter (not . esComentario) (lines texto)
    in concatMap words lineasSinComentarios

-- Predicado de verificación de comentarios ASCII en el formato PBM.
esComentario :: String -> Bool
esComentario line = case dropWhile isSpace line of
                      ('#':_) -> True
                      _       -> False

-- Descarta las líneas de cabecera (P4, dimensiones y comentarios) recorriendo el ByteString
-- para retornar exactamente el offset donde inicia la secuencia de bytes del payload binario.
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

-- Consulta el estado lógico de un píxel en la coordenada discreta (x, y).
-- Convierte coordenadas bidimensionales a la posición exacta del byte y desplaza el bit (MSB a LSB).
pixelEn :: Ancho -> B.ByteString -> Int -> Int -> Bool
pixelEn ancho bytes x y =
    let bytesPorFila = (ancho + 7) `div` 8
        byteIndex    = y * bytesPorFila + (x `div` 8)
        bitIndex     = 7 - (x `mod` 8)
        byteVal      = B.index bytes byteIndex
    in testBit byteVal bitIndex

-- Mapea cada columna x al valor f(x).
-- Implementa el requerimiento específico: cuenta píxeles negros consecutivos desde la base (abajo) hacia arriba.
extraerAlturas :: Ancho -> Alto -> B.ByteString -> VectorAlturas
extraerAlturas ancho alto bytes = [ buscarAlturaEnColumna x | x <- [0 .. ancho - 1] ]
  where
    buscarAlturaEnColumna :: Int -> Altura
    buscarAlturaEnColumna x =
      let -- 1. Secuencia de índices y descendente desde la última fila (alto - 1) hasta el tope (0)
          filasDesdeAbajo = [alto - 1, alto - 2 .. 0]
          
          -- 2. Evaluación de estado activo (negro) del píxel
          esNegro y = pixelEn ancho bytes x y
          
          -- 3. Acumulación contigua desde la base usando Lazy Evaluation
          pixelesConsecutivos = takeWhile esNegro filasDesdeAbajo
          
      -- 4. Longitud equivalente a la altura f(x)
      in length pixelesConsecutivos

-- Aproximación del área bajo la curva mediante la Suma de Riemann con Δx = 1 píxel.
calcularArea :: VectorAlturas -> Int
calcularArea = sum

-- Muestra en consola 10 puntos representativos de la distribución M[x_i] -> f(x_i).
mostrarMuestras :: VectorAlturas -> IO ()
mostrarMuestras alturas = do
  let total = length alturas
      indices = [0, 62, 125, 188, 251, 314, 377, 440, 503, total - 1]
      muestras = [(i, alturas !! i) | i <- indices, i < total]
  putStrLn "\nALGUNOS VALORES x_i -> f(x_i)"
  mapM_ (\(x, y) -> putStrLn $ "x_" ++ show x ++ " = " ++ show x ++ "  ->  f(x_" ++ show x ++ ") = " ++ show y ++ " pixeles") muestras

-- Escala la gráfica original de 567x319 a una matriz de caracteres de 80x20 para renderizar en terminal.
dibujarCurvaConsola :: VectorAlturas -> Int -> IO ()
dibujarCurvaConsola alturas altoOriginal = do
  let anchoOriginal = length alturas
      anchoConsola = 80 
      altoConsola  = 20 

      -- Factores de compresión horizontal y vertical
      factorX = fromIntegral anchoOriginal / fromIntegral anchoConsola :: Double
      alturasReducidas = [ alturas !! floor (fromIntegral i * factorX) | i <- [0 .. anchoConsola - 1] ]

      -- Construcción celda a celda de la matriz de texto
      escalaY h = floor ((fromIntegral h / fromIntegral altoOriginal) * fromIntegral altoConsola) :: Int

      construirFila y = [ if escalaY h >= y then '█' else ' ' | h <- alturasReducidas ]

      filas = [ construirFila y | y <- [altoConsola, altoConsola - 1 .. 0] ]

  putStrLn "\nREPRESENTACIÓN DE LA CURVA EN CONSOLA"
  putStrLn (replicate anchoConsola '-')
  mapM_ putStrLn filas
  putStrLn (replicate anchoConsola '-')
  
-- Formatea el vector de alturas en formato de líneas individuales de texto para archivo.
formatearAlturas :: VectorAlturas -> String
formatearAlturas alturas = unlines (map show alturas)

main :: IO ()
main = do
    let nombreArchivoEntrada = "curva_binaria_P4.pbm"
    let nombreArchivoSalida  = "alturas.txt"

    -- 1. Lectura del archivo binario
    contenido <- B.readFile nombreArchivoEntrada
    
    -- 2. Parsing de la cabecera y extracción de mapa de bits
    let (ancho, alto, bytesDatos) = parsePBM contenido

    -- 3. Extracción de alturas f(x) y cálculo del área
    let alturas = extraerAlturas ancho alto bytesDatos
    let area = calcularArea alturas

    -- 4. Impresión de metadatos de la imagen
    putStrLn $ "Imagen: " ++ show ancho ++ " x " ++ show alto ++ " pixeles"
    putStrLn $ "Area: " ++ show area ++ " pixeles cuadrados"

    -- 5. Renderizado visual y tabla de muestras
    dibujarCurvaConsola alturas alto
    mostrarMuestras alturas

    -- 6. Persistencia del vector M[x] para la etapa de Prolog
    writeFile nombreArchivoSalida (formatearAlturas alturas)
    putStrLn $ "\nVector M[x] guardado en '" ++ nombreArchivoSalida ++ "'."