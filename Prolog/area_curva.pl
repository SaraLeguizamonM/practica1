% importacion de librerias
:- encoding(utf8).
:- set_prolog_flag(double_quotes, codes).
:- use_module(library(readutil)).
:- use_module(library(apply)).

% Fuerza que la salida estandar se escriba en UTF-8, para que el
% caracter de bloque  se vea correctamente
:- catch(set_stream(user_output, encoding(utf8)), _, true).

% Cargar el archivo PBM P4, acceder a pixeles individuales, construir la funcion f(X),


read_pbm(Path, Width, Height, Bytes) :-
    read_file_to_codes(Path, Codes, [encoding(octet)]),  % lectura binaria
    append("P4", Rest0, Codes),   % verificar encabezado (P4)
    skip_ws(Rest0, Rest1),   % saltar espacios en blanco
    read_number(Rest1, Width, Rest2),    % leer ancho
    skip_ws(Rest2, Rest3),   % saltar espacios en blanco
    read_number(Rest3, Height, Rest4),   % leer alto
    Rest4 = [_UnEspacio | Bytes].   % vuelve a separar antes de pasar binarios crudos

% Saltar espacios en blanco y comentarios (que empiezan con #) en el encabezado del archivo PBM
skip_ws([C|Cs], Out) :- code_type(C, space), !, skip_ws(Cs, Out).
skip_ws([0'#|Cs], Out) :- !, skip_comentario(Cs, Cs1), skip_ws(Cs1, Out).
skip_ws(Cs, Cs).

% Saltar comentarios (que empiezan con #) hasta el final de la linea 
skip_comentario([0'\n|Cs], Cs) :- !. 
skip_comentario([_|Cs], Out) :- !, skip_comentario(Cs, Out).
skip_comentario([], []).

% Leer un numero decimal de la lista de codigos, devolviendo el numero y el resto de la lista
read_number(Cs, Number, Rest) :-
    read_digits(Cs, Digits, Rest),
    Digits \== [],
    number_codes(Number, Digits).

read_digits([C|Cs], [C|Ds], Rest) :- code_type(C, digit), !, read_digits(Cs, Ds, Rest).
read_digits(Cs, [], Cs).

% Acceder a un pixel individual (X, Y)

pixel(X, Y, Width, Bytes, Bit) :-   % X >= 0, Y >= 0, X < Width,
    BytesPorFila is (Width + 7) // 8,  % redondeo hacia arriba
    IndiceByte is Y * BytesPorFila + (X // 8),  % calcular el indice del byte que contiene el pixel (X, Y)
    nth0(IndiceByte, Bytes, Byte),  % obtener el byte correspondiente
    PosBit is 7 - (X mod 8),  % calcular la posicion del bit dentro del byte 
    Bit is (Byte >> PosBit) /\ 1.  % extraer el bit correspondiente (1 = negro, 0 = blanco)


% La funcion discreta f(X) se define como la altura de la columna X

f(X, Width, Height, Bytes, Alto) :-  
    FilaInferior is Height - 1,  
    altura_desde(X, FilaInferior, Width, Bytes, Alto).

% Calcular la altura de la columna X desde una fila específica hacia arriba
% Si es si, es 1 = negro y si es no seria 0 = blanco
altura_desde(_, Fila, _, _, 0) :- Fila < 0, !.
altura_desde(X, Fila, Width, Bytes, Cuenta) :-
    pixel(X, Fila, Width, Bytes, Bit),
    ( Bit =:= 1
    -> FilaSiguiente is Fila - 1,
       altura_desde(X, FilaSiguiente, Width, Bytes, Resto),
       Cuenta is Resto + 1
    ;  Cuenta = 0
    ).

% Construir M (todo el dominio de la funcion f) y se calcula el area bajo la curva

alturas(Width, Height, Bytes, M) :- 
    MaxX is Width - 1,
    findall(Alto, 
            ( between(0, MaxX, X),
              f(X, Width, Height, Bytes, Alto) ),
            M).


% Area como suma de riemann (delta x = 1)
area(M, Area) :- sum_list(M, Area).

% Representacion de la curva en consola (a partir de M)

% Se dibuja directamente sobre el vector de alturas M -- el mismo
% que ya se uso para calcular el area
% Se hace un muestreo, donde se reduce las filas y columnas con las mas representativas

dibujar_curva_consola(M, AltoOriginal) :- 
    length(M, AnchoOriginal),
    AnchoConsola = 80, AltoConsola = 20,
    UltCol is AnchoConsola - 1,
    findall(Alto, 
        ( between(0, UltCol, I),
          Idx is (I * AnchoOriginal) // AnchoConsola,
          nth0(Idx, M, Alto) ),
        AlturasReducidas),
    write('REPRESENTACION DE LA CURVA EN CONSOLA'), nl,
    imprimir_borde(AnchoConsola),
    forall(between(0, AltoConsola, DesdeArriba), % a diferencia de findall, este no acumula resultados
        ( Y is AltoConsola - DesdeArriba, %  sino que ejecuta la accion para cada valor, (imprimir en pantalla)
          forall(member(H, AlturasReducidas),
                 pintar_celda(H, AltoOriginal, AltoConsola, Y)),
          nl )),
    imprimir_borde(AnchoConsola).

imprimir_borde(N) :- forall(between(1, N, _), write('-')), nl.

% H: altura real de esta columna (en pixeles de la imagen)
% Y: fila actual de la rejilla de consola (0 = base)
% Se pinta '█' si la altura escalada de esta columna alcanza o
% supera la fila Y; si no, se deja un espacio en blanco.

pintar_celda(H, AltoOriginal, AltoConsola, Y) :-
    EscalaY is (H * AltoConsola) // AltoOriginal,
    ( EscalaY >= Y -> write('█') ; write(' ') ).

% Valores de muestra x_i -> f(x_i) 
% calcula un tamaño de salto para tomar aproximadamente 
% 10 muestras distribuidas uniformemente a lo largo de las N columnas.

mostrar_muestras(M) :-
    length(M, N),
    NumMuestras = 10,
    Paso is max(1, N // NumMuestras),
    UltMuestra is NumMuestras - 1,
    forall(( between(0, UltMuestra, I),
             X is I * Paso, X < N,
             nth0(X, M, Alto) ),
           format("x_~w = ~w -> f(x_~w) = ~w pixeles~n", [I, X, I, Alto])).


% Main que procesa el archivo PBM, calcula el area bajo la curva y dibuja la curva en consola
main(Path) :-
    read_pbm(Path, Width, Height, Bytes),
    format("Imagen: ~w x ~w pixeles~n", [Width, Height]),
    alturas(Width, Height, Bytes, M),
    area(M, Area),
    format("Area: ~w pixeles cuadrados~n", [Area]),
    nl, dibujar_curva_consola(M, Height),
    mostrar_muestras(M).

% Main que procesa los argumentos de la linea de comandos
main :-
    current_prolog_flag(argv, Argv),
    ( Argv = [Path|_]
    -> main(Path)
    ;  format(user_error, "Uso: swipl area_curva.pl <archivo.pbm>~n", []),
       halt(1)
    ).

:- initialization(main, main).