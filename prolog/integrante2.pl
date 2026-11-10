/* ============================================================
   PROYECTO FINAL - PROGRAMACION DECLARATIVA - CICLO 02/2026
   Sistema de solucion de integrales

   INTEGRANTE 2: Motor de integracion simbolica
     - Reglas de integracion: k, k*u, tan(x)
     - Motor principal de integracion de expresiones
     - Simplificacion basica de resultados
     - Pruebas del integrante 2

   CONTRATO DEL GRUPO (definido en integrante1.pl):
     s(Var, Funcion, Resultado)
     Var = x (atomo en minuscula)
     Funcion = expresion validada y normalizada
     Resultado = primitiva, sin la constante C

   No se requiere conocer la tecnologia de la interfaz.
   ============================================================ */

:- encoding(utf8).
:- multifile s/3.
:- discontiguous s/3.


/* ============================================================
   PARTE 1. REGLAS DE INTEGRACION DEL INTEGRANTE 2
   ============================================================ */

% --- 1) Constante:  integral de k dx = k*x  (caso base)
% Reconoce numeros, pi, e y expresiones independientes de x,
% por ejemplo: 2*pi, 2^3, cos(0).
% no_depende_de/2 esta definido por el integrante 1.
s(X, K, K*X) :-
    nonvar(K),
    no_depende_de(X, K).

% --- 2) Constante por funcion: integral de k*u dx = k*integral(u) dx
% (caso recursivo). El coeficiente puede ser 3, pi, 2*pi, etc.
% La funcion U debe depender de x; si no, la regla anterior integra
% toda la expresion como una constante. El caso directo k*x se reserva
% para el integrante 4, evitando ocultar su regla al unir los archivos.
s(X, K*U, K*RU) :-
    nonvar(K),
    no_depende_de(X, K),
    \+ no_depende_de(X, U),
    U \== X,
    s(X, U, RU).

% El signo menos delante de una funcion equivale a multiplicar por -1.
% Ejemplo: integral de -sin(x) dx = cos(x).
s(X, -U, -RU) :-
    \+ no_depende_de(X, U),
    s(X, U, RU).

% --- 3) Tangente: integral de tan(x) dx = -ln|cos(x)|  (caso base)
% El resultado requiere cos(x) distinto de cero en el intervalo
% en el que se evalua. La verificacion de los limites corresponde
% al modulo de evaluacion del integrante 3.
s(X, tan(X), -log(abs(cos(X)))).


/* ============================================================
   PARTE 2. MOTOR CENTRAL DE INTEGRACION
   ============================================================

   integrar(+Texto, -Primitiva)
     Integra una expresion recibida como texto y devuelve su
     primitiva simplificada. Falla si el texto no es valido o si
     todavia no existe una regla para esa expresion.

   integrar(+Texto, -Primitiva, -Estado)
     Version para la interfaz y para el futuro modulo de evaluacion.
     Estado = ok | error(Mensaje).
     Si hay un error, Primitiva = sin_resultado.

   En ambos casos se reutilizan validar_texto/3 (integrante 1) y
   todas las reglas s/3 que el grupo agregue a la base de conocimiento.
   No se implementan aqui reglas asignadas a otros integrantes.

   Ejemplos:
     ?- integrar('3*x^2 + tan(x)', R).
     R = x^3-log(abs(cos(x))).

     ?- integrar('2x', R, Estado).
     R = sin_resultado,
     Estado = error(...).
   ============================================================ */

integrar(Texto, Primitiva) :-
    integrar(Texto, Primitiva, ok).

integrar(Texto, Primitiva, Estado) :-
    validar_texto(Texto, Expr, Validacion),
    (   Validacion == ok
    ->  integrar_expresion(Expr, Primitiva, Estado)
    ;   Primitiva = sin_resultado,
        Estado = Validacion
    ).

% Integracion de un termino ya validado/normalizado por el integrante 1.
% Este predicado centraliza la llamada a s/3 y su simplificacion.
integrar_expresion(Expr, Primitiva, Estado) :-
    catch(
        (   once(s(x, Expr, ResultadoSinSimplificar))
        ->  simplificar(ResultadoSinSimplificar, Primitiva),
            Estado = ok
        ;   Primitiva = sin_resultado,
            Estado = error('No hay una regla de integracion para esta expresion')
        ),
        Error,
        (   Primitiva = sin_resultado,
            message_to_string(Error, Mensaje),
            Estado = error(Mensaje)
        )
    ).


/* ============================================================
   PARTE 3. SIMPLIFICACION BASICA DE EXPRESIONES SIMBOLICAS
   ============================================================

   simplificar(+Expresion, -Resultado)

   La simplificacion es recursiva y conserva expresiones simbolicas:
     0 + u       -> u         1 * u     -> u
     0 * u       -> 0         u / 1     -> u
     u + (-v)    -> u - v     -(-u)     -> u
     x^1         -> x         x^0       -> 1
     3*(x^3/3)  -> x^3       2*(x^3/3) -> 2*x^3/3

   Tambien resuelve operaciones entre numeros. No intenta
   integracion adicional ni conversion de funciones no reconocidas.
   ============================================================ */

% Caso base: numeros, atomos (x, pi, e) y otros terminos atomicos.
simplificar(E, E) :-
    atomic(E), !.

% Caso recursivo: simplifica los argumentos y luego la operacion.
simplificar(E, R) :-
    E =.. [Op | Args],
    maplist(simplificar, Args, SArgs),
    T =.. [Op | SArgs],
    (   simplificacion_local(T, S)
    ->  simplificar(S, R)
    ;   R = T
    ).

% Sumas.
simplificacion_local(0 + B, B) :- !.
simplificacion_local(A + 0, A) :- !.
simplificacion_local(A + (-B), A - B) :- !.
simplificacion_local(A + B, R) :-
    number(A), number(B), !,
    R is A + B.

% Restas.
simplificacion_local(A - 0, A) :- !.
simplificacion_local(0 - B, -B) :- !.
simplificacion_local(A - (-B), A + B) :- !.
simplificacion_local(A - B, R) :-
    number(A), number(B), !,
    R is A - B.

% Menos unario.
simplificacion_local(-(-A), A) :- !.
simplificacion_local(-A, R) :-
    number(A), !,
    R is -A.

% Productos: elementos neutros y producto por cero.
% Se incluyen 0.0, 1.0 y -1.0, ademas de sus versiones enteras.
simplificacion_local(A * _, 0) :- number(A), A =:= 0, !.
simplificacion_local(_ * A, 0) :- number(A), A =:= 0, !.
simplificacion_local(A * B, B) :- number(A), A =:= 1, !.
simplificacion_local(A * B, A) :- number(B), B =:= 1, !.
simplificacion_local(A * B, -B) :- number(A), A =:= -1, !.
simplificacion_local(A * B, -A) :- number(B), B =:= -1, !.

% Gestion de signos y coeficientes.
simplificacion_local(A * (-B), -(A*B)) :- !.
simplificacion_local((-A) * B, -(A*B)) :- !.
simplificacion_local(A * B, R) :-
    number(A), number(B), !,
    R is A * B.

% Lleva el coeficiente a una fraccion, sin perder exactitud simbolica.
simplificacion_local(K * (A/D), (K*A)/D) :-
    number(K), number(D), D =\= 0, !.

% Divisiones entre coeficientes y denominadores iguales.
simplificacion_local((K*A)/D, A) :-
    number(K), number(D), D =\= 0, K =:= D, !.

% Division exacta entre dos coeficientes enteros.
simplificacion_local((K*A)/D, Q*A) :-
    integer(K), integer(D), D =\= 0,
    0 is K mod D, !,
    Q is K // D.

% Division entre uno y operaciones numericas seguras.
simplificacion_local(A / 1, A) :- !.
simplificacion_local(A / B, R) :-
    number(A), number(B), B =\= 0, !,
    R is A / B.

% Potencias obvias; no se simplifica 0^0.
simplificacion_local(A ^ 1, A) :- !.
simplificacion_local(A ^ 0, 1) :-
    (number(A) -> A =\= 0 ; true), !.
simplificacion_local(1 ^ _, 1) :- !.
simplificacion_local(0 ^ B, 0) :-
    number(B), B > 0, !.
simplificacion_local(A ^ B, R) :-
    number(A), number(B),
    \+ (A =:= 0, B =:= 0),
    (A > 0 ; integer(B)),
    catch(R is A^B, _, fail), !.


/* ============================================================
   PARTE 4. PRUEBAS DEL INTEGRANTE 2
   ============================================================

   Ejecutar, habiendo cargado integrante1.pl e integrante2.pl:

     ?- probar_integrante1.
     ?- probar_integrante2.

   Todas las pruebas de esta seccion funcionan con las partes 1 y 2;
   no necesitan las partes 3 ni 4. Devuelven true si pasan todas.
   ============================================================ */

probar_integrante2 :-
    Pruebas = [
        prueba('Constante numerica',
               (integrar('7', R1), R1 == 7*x)),
        prueba('Constante simbolica',
               (integrar('pi', R2), R2 == pi*x)),
        prueba('Constante compuesta',
               (integrar('2^3', R3), R3 == 8*x)),
        prueba('Coeficiente simbolico compuesto',
               (integrar('2*pi*x^2', R14),
                R14 == (2*pi)*(x^3/3))),
        prueba('Potencia del integrante 1',
               (integrar('x^0', R15), R15 == x)),
        prueba('Potencia especial del integrante 1',
               (integrar('x^-1', R16), R16 == log(abs(x)))),
        prueba('Coeficiente por potencia',
               (integrar('4*x^2', R4), R4 == (4*x^3)/3)),
        prueba('Coeficiente que se cancela',
               (integrar('3*x^2', R5), R5 == x^3)),
        prueba('Coeficiente por seno',
               (integrar('3*sin(x)', R6), R6 == -(3*cos(x)))),
        prueba('Tangente',
               (integrar('tan(x)', R7), R7 == -log(abs(cos(x))))),
        prueba('Suma de reglas de ambos integrantes',
               (integrar('x^2 + tan(x)', R8),
                R8 == (x^3/3 - log(abs(cos(x)))))),
        prueba('Factor por suma de funciones',
               (integrar('2*(x^2 + sin(x))', R9),
                R9 == 2*(x^3/3 - cos(x)))),
        prueba('Menos unario sobre funcion',
               (integrar('-sin(x)', R10), R10 == cos(x))),
        prueba('Error de sintaxis',
               (integrar('2x', _, E11), E11 = error(_))),
        prueba('Funcion no reconocida',
               (integrar('sen(x)', _, E12), E12 = error(_))),
        prueba('Division entre cero',
               (integrar('x/0', _, E13), E13 = error(_)))
    ],
    maplist(ejecutar_prueba_integrante2, Pruebas, Resultados),
    include(=(ok), Resultados, Correctas),
    length(Resultados, Total),
    length(Correctas, Exitos),
    format('--- Integrante 2: ~d de ~d pruebas correctas ---~n',
           [Exitos, Total]),
    Exitos =:= Total.

ejecutar_prueba_integrante2(prueba(Nombre, Consulta), Resultado) :-
    (   catch(once(call(Consulta)), _, fail)
    ->  Resultado = ok,
        format('  [OK] ~w~n', [Nombre])
    ;   Resultado = fallo,
        format('  [FALLO] ~w~n', [Nombre])
    ).
