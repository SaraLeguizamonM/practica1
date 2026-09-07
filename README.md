# Práctica 1: Haskell y Prolog

## Integrantes

* Sara Nicolle Leguizamón Moreno
* Maria Fernanda Córdoba Marín

## Entorno de desarrollo

* Sistema operativo: Windows
* Editor/IDE: Visual Studio Code
* Terminal: PowerShell
* Lenguajes utilizados:

  * Haskell
  * Prolog (SWI-Prolog)

## Estructura del proyecto

```text
practica1/
├── README.md
├── Haskell/
│   └── Main.hs
├── Prolog/
│   └── area_curva.pl
└── curva_binaria_P4.pbm
```

## Solución en Haskell

### Compilación

Desde la carpeta raíz del proyecto, ejecutar:

```powershell
ghc Haskell\Main.hs -o Haskell\Main.exe
```

Esto genera el ejecutable `Main.exe` dentro de la carpeta `Haskell`.

### Ejecución

Una vez compilado, ejecutar:

```powershell
.\Haskell\Main.exe
```

El programa utiliza el archivo `curva_binaria_P4.pbm` ubicado en la carpeta raíz del proyecto. También genera el archivo `alturas.txt` con el vector de alturas obtenido a partir de la imagen.

## Solución en Prolog

La solución utiliza SWI-Prolog.

Desde la carpeta raíz del proyecto, ejecutar:

```powershell
swipl Prolog\area_curva.pl -- curva_binaria_P4.pbm
```

También se puede ejecutar utilizando directamente la ruta de instalación de SWI-Prolog:

```powershell
& "C:\Program Files\swipl\bin\swipl.exe" Prolog\area_curva.pl -- curva_binaria_P4.pbm
```

## Estrategia para mostrar la imagen grande en la consola

Debido al tamaño de la imagen, se procesa la imagen por columnas para obtener la altura correspondiente a cada columna de la curva.

Con estas alturas se construye una representación de la curva en la consola utilizando caracteres. De esta manera, se puede visualizar la forma general de la imagen sin tener que mostrar cada píxel individualmente.

El vector de alturas también se utiliza para realizar el cálculo del área.

## Cálculo del área

El área se calcula mediante una suma de Riemann.

Cada columna de la imagen representa un rectángulo de ancho 1 píxel y cuya altura corresponde a la cantidad de píxeles de la región de la curva en esa columna.

Por lo tanto, el área se obtiene sumando las áreas de todos los rectángulos:

```
Área ≈ Σ hᵢ · Δx
```
Como cada columna tiene un ancho de:
```
Δx = 1 píxel
```
el cálculo se reduce a:
```
Área = Σ hᵢ
```
donde hᵢ es la altura de la curva en cada columna.

Para el archivo suministrado **curva_binaria_P4.pbm**, se obtuvo:

Área = 108660 píxeles cuadrados.

<img width="781" height="449" alt="image" src="https://github.com/user-attachments/assets/2d92ae46-fc54-44a7-828f-629cf3fc62bd" />

