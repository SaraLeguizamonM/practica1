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
    read_file_to_codes(Path, Codes, [encoding(octet)]),
    append("P4", Rest0, Codes),
    skip_ws(Rest0, Rest1),
    read_number(Rest1, Width, Rest2),
    skip_ws(Rest2, Rest3),
    read_number(Rest3, Height, Rest4),
    Rest4 = [_UnEspacio | Bytes].   % un solo separador antes del binario


skip_ws([C|Cs], Out) :- code_type(C, space), !, skip_ws(Cs, Out).
skip_ws([0'#|Cs], Out) :- !, skip_comentario(Cs, Cs1), skip_ws(Cs1, Out).
skip_ws(Cs, Cs).

skip_comentario([0'\n|Cs], Cs) :- !.
skip_comentario([_|Cs], Out) :- !, skip_comentario(Cs, Out).
skip_comentario([], []).

read_number(Cs, Number, Rest) :-
    read_digits(Cs, Digits, Rest),
    Digits \== [],
    number_codes(Number, Digits).

read_digits([C|Cs], [C|Ds], Rest) :- code_type(C, digit), !, read_digits(Cs, Ds, Rest).
read_digits(Cs, [], Cs).

% Acceder a un pixel individual (X, Y)

pixel(X, Y, Width, Bytes, Bit) :-
    BytesPorFila is (Width + 7) // 8,
    IndiceByte is Y * BytesPorFila + (X // 8),
    nth0(IndiceByte, Bytes, Byte),
    PosBit is 7 - (X mod 8),
    Bit is (Byte >> PosBit) /\ 1.

% La funcion discreta f(X) se define como la altura de la columna X, es decir, cuantos pixeles negros

f(X, Width, Height, Bytes, Alto) :-
    FilaInferior is Height - 1,
    altura_desde(X, FilaInferior, Width, Bytes, Alto).


altura_desde(_, Fila, _, _, 0) :- Fila < 0, !.
altura_desde(X, Fila, Width, Bytes, Cuenta) :-
    pixel(X, Fila, Width, Bytes, Bit),
    ( Bit =:= 1
    -> FilaSiguiente is Fila - 1,
       altura_desde(X, FilaSiguiente, Width, Bytes, Resto),
       Cuenta is Resto + 1
    ;  Cuenta = 0
    ).

% Construir M de forma declarativa

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
    forall(between(0, AltoConsola, DesdeArriba),
        ( Y is AltoConsola - DesdeArriba,
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

mostrar_muestras(M) :-
    length(M, N),
    NumMuestras = 10,
    Paso is max(1, N // NumMuestras),
    UltMuestra is NumMuestras - 1,
    forall(( between(0, UltMuestra, I),
             X is I * Paso, X < N,
             nth0(X, M, Alto) ),
           format("x_~w = ~w -> f(x_~w) = ~w pixeles~n", [I, X, I, Alto])).


% Main path

main(Path) :-
    read_pbm(Path, Width, Height, Bytes),
    format("Imagen: ~w x ~w pixeles~n", [Width, Height]),
    alturas(Width, Height, Bytes, M),
    area(M, Area),
    format("Area: ~w pixeles cuadrados~n", [Area]),
    nl, dibujar_curva_consola(M, Height),
    mostrar_muestras(M).


% Main principal
main :-
    current_prolog_flag(argv, Argv),
    ( Argv = [Path|_]
    -> main(Path)
    ;  format(user_error, "Uso: swipl area.pl <archivo.pbm>~n", []),
       halt(1)
    ).

:- initialization(main, main).