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

## Descripción del Proyecto

Esta práctica consiste en resolver un mismo problema matemático utilizando dos paradigmas de programación distintos: **Programación Funcional (Haskell)** y **Programación Lógica (Prolog)**.

El objetivo principal es leer e interpretar una imagen binaria en formato **PBM P4** (`curva_binaria_P4.pbm`) para calcular el **área bajo la curva** mediante una **Suma de Riemann de forma discreta**. 

### Fundamentación Matemática y Algorítmica
1. **Interpretación de la imagen:** Para cada posición horizontal $x$, el programa inspecciona la columna correspondiente de abajo hacia arriba y cuenta los píxeles negros consecutivos. Este conteo define el valor de la función discreta $f(x)$ (altura de la curva en $x$).
2. **Estructura de Alturas:** Se construye un vector o lista de alturas $M = [f(0), f(1), f(2), ..., f(n-1)]$.
3. **Suma de Riemann:** Asumiendo que el ancho de cada columna es $\Delta x = 1$ píxel, el área total $A$ en píxeles cuadrados equivale a la suma directa de las alturas:
   $$A = \sum_{x=0}^{n-1} f(x)$$
4. **Visualización en Consola:** Dado que las dimensiones de la imagen original superan el tamaño estándar de una ventana de terminal, se implementó una estrategia de escalado/muestreo para generar una representación compacta de la curva en texto sin perder su forma general.

*Ambas soluciones obtienen el mismo valor exacto de área, demostrando cómo dos paradigmas conceptualmente opuestos convergen en el mismo resultado computacional.*

## Solución en Haskell

### Compilación

Desde la carpeta raíz del proyecto, ejecutar:

```powershell
ghc Haskell\Main.hs -o Haskell\Main.exe
```

Esto genera el ejecutable `Main.exe` dentro de la carpeta `Haskell`.

Imagen de la curva

<img width="781" height="449" alt="image" src="https://github.com/user-attachments/assets/2d92ae46-fc54-44a7-828f-629cf3fc62bd" />

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

Imagen de la curva

<img width="921" height="644" alt="image" src="https://github.com/user-attachments/assets/93a33c38-660e-4bbb-87d0-a90cadae9e63" />

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





