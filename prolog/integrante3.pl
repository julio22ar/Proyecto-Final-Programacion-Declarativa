/* ============================================================
   PROYECTO FINAL - PROGRAMACION DECLARATIVA - CICLO 02/2026
   Sistema de solucion de integrales

   INTEGRANTE 3: Evaluacion de integrales y calculo de areas
     - Reglas de integracion:  x,  u - v,  a^x
     - Evaluacion numerica de la primitiva: F(b) - F(a)
     - Validacion de los limites y del intervalo [a, b]
     - Revision de discontinuidades dentro del intervalo
     - Area geometrica total bajo la curva
     - Pruebas del integrante 3

   CONTRATO DEL GRUPO (definido en integrante1.pl):
     s(Var, Funcion, Resultado)   Var = x, Resultado sin + C

   Reutiliza:
     validar_texto/3, no_depende_de/2   (integrante 1)
     integrar/3                         (integrante 2)
   ============================================================ */

:- encoding(utf8).
:- multifile s/3.
:- discontiguous s/3.


/* ============================================================
   PARTE 1. REGLAS DE INTEGRACION DEL INTEGRANTE 3
   (sin cortes "!" para no bloquear las clausulas de los demas)
   ============================================================ */

% --- 1) Variable:  ∫ x dx = x^2 / 2   (caso base)
% Es un caso particular de x^n con n = 1, pero el usuario lo escribe
% como "x" (no como "x^1"), por eso necesita su propia regla.
s(X, X, X^2/2).

% --- 2) Resta:  ∫ (u - v) dx = ∫ u dx - ∫ v dx   (caso recursivo)
% Igual que la suma del integrante 1: cada termino se integra
% llamando otra vez a s/3, asi que u y v pueden ser cualquier
% funcion que sepa integrar el grupo (x^2 - sin(x) - 3, etc.).
s(X, U - V, RU - RV) :-
    s(X, U, RU),
    s(X, V, RV).

% --- 3) Exponencial:  ∫ a^x dx = a^x / ln(a),   a > 0,  a ≠ 1
% Caso especial a = e:  ∫ e^x dx = e^x   (porque ln(e) = 1)
s(X, e^X, e^X).

s(X, A^X, A^X / log(A)) :-
    A \== e,
    base_exponencial(X, A, ValorA),
    ValorA > 0,
    ValorA =\= 1.

% Caso degenerado a = 1:  1^x = 1, entonces ∫ 1^x dx = x
s(X, A^X, X) :-
    base_exponencial(X, A, ValorA),
    ValorA =:= 1.

% Si a <= 0, a^x no esta definida para todo x real: no hay regla,
% y el motor (integrante 2) responde "No hay una regla...".

% base_exponencial(+X, +A, -Valor): A es una constante (no depende de x)
% y se puede calcular su valor numerico (2, pi, 2*pi, 1/2 ...).
base_exponencial(X, A, Valor) :-
    nonvar(A),
    no_depende_de(X, A),
    catch(evaluar_en(A, 0, Valor), _, fail).


/* ============================================================
   PARTE 2. EVALUADOR NUMERICO
   ============================================================

   evaluar_en(+Expr, +ValorX, -Valor)
     Sustituye x por ValorX y calcula el resultado (numero real).
     Si la expresion no se puede evaluar en ese punto, lanza
     eval_error(Mensaje), por ejemplo division entre cero o
     logaritmo de un numero no positivo.

   Ejemplo:
     ?- evaluar_en(x^3/3 - cos(x), 2, V).
     V = 3.0828...
   ------------------------------------------------------------ */

% Casos base
evaluar_en(N, _, V) :- number(N), !, V is float(N).
evaluar_en(x, X, V) :- !, V is float(X).
evaluar_en(pi, _, V) :- !, V is pi.
evaluar_en(e, _, V) :- !, V is e.

% Operadores
evaluar_en(A + B, X, V) :- !,
    evaluar_en(A, X, VA), evaluar_en(B, X, VB), V is VA + VB.
evaluar_en(A - B, X, V) :- !,
    evaluar_en(A, X, VA), evaluar_en(B, X, VB), V is VA - VB.
evaluar_en(-A, X, V) :- !,
    evaluar_en(A, X, VA), V is -VA.
evaluar_en(A * B, X, V) :- !,
    evaluar_en(A, X, VA), evaluar_en(B, X, VB), V is VA * VB.
evaluar_en(A / B, X, V) :- !,
    evaluar_en(A, X, VA), evaluar_en(B, X, VB),
    (   abs(VB) < 1.0e-12
    ->  throw(eval_error('division entre cero'))
    ;   V is VA / VB
    ).
evaluar_en(A ^ B, X, V) :- !,
    evaluar_en(A, X, VA), evaluar_en(B, X, VB),
    potencia(VA, VB, V).

% Funciones de un argumento
evaluar_en(E, X, V) :-
    compound(E),
    E =.. [F, A],
    funcion_numerica(F, Op), !,
    evaluar_en(A, X, VA),
    aplicar_funcion(Op, VA, V).

evaluar_en(E, _, _) :-
    format(atom(Msg), 'no se puede evaluar ~w', [E]),
    throw(eval_error(Msg)).

% Nombre en el proyecto -> nombre de la funcion aritmetica de SWI-Prolog
funcion_numerica(sin, sin).        funcion_numerica(cos, cos).
funcion_numerica(tan, tan).        funcion_numerica(asin, asin).
funcion_numerica(acos, acos).      funcion_numerica(atan, atan).
funcion_numerica(sh, sinh).        funcion_numerica(cosh, cosh).
funcion_numerica(tanh, tanh).      funcion_numerica(arcsinh, asinh).
funcion_numerica(arccosh, acosh).  funcion_numerica(arctanh, atanh).
funcion_numerica(log, log).        funcion_numerica(abs, abs).

% Potencia real con control de dominio
potencia(B, P, _) :-
    B =:= 0, P < 0, !,
    throw(eval_error('cero elevado a una potencia negativa')).
potencia(B, P, _) :-
    B < 0, P =\= round(P), !,
    throw(eval_error('raiz de un numero negativo')).
potencia(B, P, V) :-
    B < 0, !,
    E is integer(P), V is B ** E.
potencia(B, P, V) :-
    V is B ** P.

% Funciones con control de dominio
aplicar_funcion(log, A, _) :- A =< 0, !,
    throw(eval_error('logaritmo de un numero no positivo')).
aplicar_funcion(tan, A, _) :- abs(cos(A)) < 1.0e-12, !,
    throw(eval_error('tan(x) no esta definida (cos(x) = 0)')).
aplicar_funcion(Op, A, _) :- memberchk(Op, [asin, acos]), abs(A) > 1, !,
    throw(eval_error('asin/acos solo aceptan valores entre -1 y 1')).
aplicar_funcion(acosh, A, _) :- A < 1, !,
    throw(eval_error('arccosh solo acepta valores >= 1')).
aplicar_funcion(atanh, A, _) :- abs(A) >= 1, !,
    throw(eval_error('arctanh solo acepta valores entre -1 y 1')).
aplicar_funcion(Op, A, V) :-
    T =.. [Op, A],
    V is T.

% evaluar_seguro(+Expr, +X, -Valor, -Estado): no lanza excepciones.
evaluar_seguro(Expr, X, V, Estado) :-
    catch(( evaluar_en(Expr, X, V), Estado = ok ),
          Error,
          ( V = sin_resultado, mensaje_eval(Error, X, Estado) )).

mensaje_eval(eval_error(M), X, error(Msg)) :- !,
    format(atom(Msg), 'En x = ~4f: ~w', [X, M]).
mensaje_eval(_, X, error(Msg)) :-
    format(atom(Msg), 'En x = ~4f: la expresion no se puede evaluar', [X]).


/* ============================================================
   PARTE 3. VALIDACION DE LIMITES E INTERVALO
   ============================================================

   validar_intervalo(+A, +B, -Va, -Vb, -Estado)
     A, B   : limites como numero o texto ('0', 'pi', 'pi/2', '-1.5')
     Va, Vb : valores numericos de los limites
     Estado : ok | error(Mensaje)

   Reglas:
     - Cada limite debe ser una expresion constante valida
       (se reutiliza validar_texto/3 del integrante 1).
     - Un limite no puede contener x.
     - Debe cumplirse a <= b.  (Si a = b la integral vale 0.)
   ------------------------------------------------------------ */

validar_intervalo(A, B, Va, Vb, Estado) :-
    leer_limite(A, 'inferior', Va, EA),
    (   EA \== ok
    ->  Vb = sin_resultado, Estado = EA
    ;   leer_limite(B, 'superior', Vb, EB),
        (   EB \== ok
        ->  Estado = EB
        ;   Va > Vb
        ->  Estado = error('Intervalo no valido: el limite inferior debe ser menor o igual que el superior')
        ;   Estado = ok
        )
    ).

leer_limite(L, _, V, ok) :-
    number(L), !,
    V is float(L).
leer_limite(L, Nombre, V, Estado) :-
    validar_texto(L, Expr, E0),
    (   E0 = error(M)
    ->  V = sin_resultado,
        format(atom(Msg), 'Limite ~w no valido: ~w', [Nombre, M]),
        Estado = error(Msg)
    ;   \+ no_depende_de(x, Expr)
    ->  V = sin_resultado,
        format(atom(Msg), 'Limite ~w no valido: no puede contener x', [Nombre]),
        Estado = error(Msg)
    ;   evaluar_seguro(Expr, 0, V, E1),
        (   E1 == ok
        ->  Estado = ok
        ;   format(atom(Msg), 'Limite ~w no valido: no se puede calcular', [Nombre]),
            Estado = error(Msg)
        )
    ).


/* ============================================================
   PARTE 4. REVISION DE DISCONTINUIDADES EN [a, b]
   ============================================================

   El teorema fundamental del calculo (F(b) - F(a)) solo es valido
   si f es continua en todo [a, b]. Se revisa de dos formas:

   1) Se evalua f en muchos puntos del intervalo: si en algun punto
      no se puede evaluar (division entre cero, raiz de negativo...),
      el intervalo no es valido.

   2) Se buscan "expresiones criticas" que no pueden valer 0:
      denominadores, bases con exponente negativo y cos(u) dentro
      de tan(u). Si una cambia de signo entre dos muestras, por el
      teorema del valor intermedio vale 0 en medio: ahi f tiene una
      asintota vertical aunque ninguna muestra caiga justo encima.
   ------------------------------------------------------------ */

muestras(2000).

revisar_continuidad(F, A, B, Estado) :-
    muestras(N),
    puntos_intervalo(A, B, N, Puntos),
    (   member(P, Puntos),
        evaluar_seguro(F, P, _, E),
        E \== ok
    ->  E = error(M),
        format(atom(Msg), 'La funcion no es continua en el intervalo. ~w', [M]),
        Estado = error(Msg)
    ;   expresiones_criticas(F, Criticas),
        member(G, Criticas),
        cambio_de_signo(G, Puntos, C)
    ->  format(atom(Msg),
               'Discontinuidad en el intervalo cerca de x = ~4f: no se puede aplicar F(b) - F(a)',
               [C]),
        Estado = error(Msg)
    ;   Estado = ok
    ).

% Lista de N+1 puntos equiespaciados entre A y B (incluye ambos extremos)
puntos_intervalo(A, B, _, [A]) :- A =:= B, !.
puntos_intervalo(A, B, N, Puntos) :-
    H is (B - A) / N,
    N1 is N - 1,
    findall(P, ( between(0, N1, I), P is A + I * H ), Puntos0),
    append(Puntos0, [B], Puntos).          % B exacto, sin error de redondeo

% expresiones_criticas(+F, -Lista): expresiones que no pueden valer 0
expresiones_criticas(F, Lista) :-
    findall(G, critica(F, G), L0),
    sort(L0, Lista).

critica(_ / D, D) :- \+ number(D).
critica(B ^ P, B) :- number(P), P < 0, \+ number(B).
critica(tan(U), cos(U)).
critica(E, G) :-
    compound(E),
    E =.. [_ | Args],
    member(A, Args),
    critica(A, G).

% cambio_de_signo(+G, +Puntos, -C): G cambia de signo entre dos puntos
% consecutivos; C es el punto aproximado (se refina por biseccion).
cambio_de_signo(G, [P1, P2 | Resto], C) :-
    (   catch(evaluar_en(G, P1, V1), _, fail),
        catch(evaluar_en(G, P2, V2), _, fail),
        V1 * V2 < 0
    ->  biseccion(G, P1, P2, 50, C)
    ;   cambio_de_signo(G, [P2 | Resto], C)
    ).

biseccion(_, A, B, 0, C) :- !, C is (A + B) / 2.
biseccion(G, A, B, K, C) :-
    M is (A + B) / 2,
    evaluar_en(G, A, VA),
    evaluar_en(G, M, VM),
    K1 is K - 1,
    (   VM =:= 0
    ->  C = M
    ;   VA * VM < 0
    ->  biseccion(G, A, M, K1, C)
    ;   biseccion(G, M, B, K1, C)
    ).


/* ============================================================
   PARTE 5. INTEGRAL DEFINIDA:  F(b) - F(a)
   ============================================================

   integral_definida(+Texto, +A, +B, -Primitiva, -Valor, -Estado)
     Texto      : funcion escrita por el usuario, p. ej. 'x^2 - sin(x)'
     A, B       : limites (numero o texto: 0, 'pi', 'pi/2')
     Primitiva  : F(x) simplificada, sin + C   (o sin_resultado)
     Valor      : numero real F(b) - F(a)       (o sin_resultado)
     Estado     : ok | error(Mensaje)  -> el mensaje se muestra tal cual

   Pasos:
     1. Obtener la primitiva con integrar/3 (integrante 2).
     2. Validar los limites y el intervalo.
     3. Revisar que f sea continua en [a, b].
     4. Calcular F(b) - F(a)   (teorema fundamental del calculo).

   Ejemplos:
     ?- integral_definida('x^2', 0, 3, F, V, E).
     F = x^3/3, V = 9.0, E = ok.

     ?- integral_definida('1/x', -1, 1, F, V, E).
     V = sin_resultado, E = error('Discontinuidad ...').
   ------------------------------------------------------------ */

integral_definida(Texto, A, B, Primitiva, Valor, Estado) :-
    integrar(Texto, Primitiva, E1),                       % paso 1
    (   E1 \== ok
    ->  Valor = sin_resultado, Estado = E1
    ;   validar_intervalo(A, B, Va, Vb, E2),              % paso 2
        (   E2 \== ok
        ->  Valor = sin_resultado, Estado = E2
        ;   validar_texto(Texto, F, _),
            revisar_continuidad(F, Va, Vb, E3),           % paso 3
            (   E3 \== ok
            ->  Valor = sin_resultado, Estado = E3
            ;   evaluar_primitiva(Primitiva, Va, Vb, Valor, Estado)   % paso 4
            )
        )
    ).

% evaluar_primitiva(+F, +A, +B, -Valor, -Estado): Valor = F(B) - F(A)
evaluar_primitiva(F, A, B, Valor, Estado) :-
    evaluar_seguro(F, B, Fb, EB),
    evaluar_seguro(F, A, Fa, EA),
    (   EB \== ok -> Valor = sin_resultado, Estado = EB
    ;   EA \== ok -> Valor = sin_resultado, Estado = EA
    ;   V0 is Fb - Fa,
        limpiar_cero(V0, Valor),
        Estado = ok
    ).

% Errores de redondeo como 1.2e-16 se muestran como 0.0
limpiar_cero(V, 0.0) :- abs(V) < 1.0e-10, !.
limpiar_cero(V, V).


/* ============================================================
   PARTE 6. AREA GEOMETRICA BAJO LA CURVA
   ============================================================

   area_bajo_curva(+Texto, +A, +B, -Area, -Estado)

   F(b) - F(a) es un valor CON SIGNO: lo que esta debajo del eje x
   resta. El area total se calcula dividiendo [a, b] en los puntos
   donde f(x) = 0 y sumando el valor absoluto de cada tramo:

       Area = |F(c1) - F(a)| + |F(c2) - F(c1)| + ... + |F(b) - F(cn)|

   Ejemplo:  ∫ sin(x) de 0 a 2*pi = 0,  pero el area es 4.
   ------------------------------------------------------------ */

area_bajo_curva(Texto, A, B, Area, Estado) :-
    integral_definida(Texto, A, B, Primitiva, _, E0),
    (   E0 \== ok
    ->  Area = sin_resultado, Estado = E0
    ;   validar_texto(Texto, F, _),
        validar_intervalo(A, B, Va, Vb, _),
        muestras(N),
        puntos_intervalo(Va, Vb, N, Puntos),
        catch(( raices(F, Puntos, Raices),
                append([Va | Raices], [Vb], Cortes),
                suma_tramos(Primitiva, Cortes, 0.0, A0),
                limpiar_cero(A0, Area),
                Estado = ok ),
              _,
              ( Area = sin_resultado,
                Estado = error('No se pudo calcular el area en el intervalo') ))
    ).

% Puntos interiores donde f cambia de signo (raices de f)
raices(F, [P1, P2 | Resto], Raices) :- !,
    evaluar_en(F, P1, V1),
    evaluar_en(F, P2, V2),
    (   V1 * V2 < 0
    ->  biseccion(F, P1, P2, 50, C),
        Raices = [C | Rs]
    ;   V2 =:= 0, Resto \== []
    ->  Raices = [P2 | Rs]
    ;   Raices = Rs
    ),
    raices(F, [P2 | Resto], Rs).
raices(_, _, []).

suma_tramos(Prim, [P1, P2 | Resto], Acum, Area) :- !,
    evaluar_en(Prim, P1, F1),
    evaluar_en(Prim, P2, F2),
    Acum1 is Acum + abs(F2 - F1),
    suma_tramos(Prim, [P2 | Resto], Acum1, Area).
suma_tramos(_, _, Area, Area).


/* ============================================================
   PARTE 7. PRUEBAS DEL INTEGRANTE 3
   ============================================================

   Ejecutar (con los archivos 1, 2 y 3 cargados):
     ?- probar_integrante3.

   Demostracion paso a paso para la defensa:
     ?- demo_integral('x^2 - 1', 0, 2).
   ------------------------------------------------------------ */

cerca(V, Esperado) :- number(V), abs(V - Esperado) < 1.0e-6.

probar_integrante3 :-
    Pruebas = [
        % --- Reglas de integracion
        prueba('Regla x',
               (integrar('x', R1), R1 == x^2/2)),
        prueba('Regla u - v',
               (integrar('x^2 - sin(x)', R2), R2 == x^3/3 + cos(x))),
        prueba('Resta con constante',
               (integrar('x - 3', R3), R3 == x^2/2 - 3*x)),
        prueba('Exponencial 2^x',
               (integrar('2^x', R4), R4 == 2^x/log(2))),
        prueba('Exponencial e^x',
               (integrar('e^x', R5), R5 == e^x)),
        prueba('Exponencial pi^x',
               (integrar('pi^x', R6), R6 == pi^x/log(pi))),
        prueba('Base 1 (1^x = 1)',
               (integrar('1^x', R7), R7 == x)),
        prueba('Base negativa: sin regla',
               (integrar('(-2)^x', _, E8), E8 = error(_))),
        prueba('Base cero: sin regla',
               (integrar('0^x', _, E9), E9 = error(_))),
        % --- Integral definida: resultados positivos, negativos y cero
        prueba('Positivo: x^2 de 0 a 3 = 9',
               (integral_definida('x^2', 0, 3, _, V10, ok), cerca(V10, 9))),
        prueba('Negativo: x de -2 a 0 = -2',
               (integral_definida('x', -2, 0, _, V11, ok), cerca(V11, -2))),
        prueba('Negativo: x^2 - x de 0 a 1 = -1/6',
               (integral_definida('x^2 - x', 0, 1, _, V12, ok), cerca(V12, -1/6))),
        prueba('Cero: sin(x) de -pi a pi',
               (integral_definida('sin(x)', '-pi', pi, _, V13, ok), V13 =:= 0)),
        prueba('Cero: a = b',
               (integral_definida('x^2', 2, 2, _, V14, ok), V14 =:= 0)),
        prueba('Exponencial: e^x de 0 a 1 = e - 1',
               (integral_definida('e^x', 0, 1, _, V15, ok), cerca(V15, e - 1))),
        prueba('Exponencial: 2^x de 0 a 1 = 1/ln 2',
               (integral_definida('2^x', 0, 1, _, V16, ok), cerca(V16, 1/log(2)))),
        prueba('Limite simbolico: sin(x) de 0 a pi/2 = 1',
               (integral_definida('sin(x)', 0, 'pi/2', _, V17, ok), cerca(V17, 1))),
        prueba('Tangente continua: tan(x) de 0 a 1',
               (integral_definida('tan(x)', 0, 1, _, V18, ok),
                cerca(V18, -log(cos(1))))),
        % --- Limites e intervalo no validos
        prueba('Intervalo invertido (a > b)',
               integral_definida('x', 3, 1, _, sin_resultado, error(_))),
        prueba('Limite con texto no valido',
               integral_definida('x', 'abc', 1, _, sin_resultado, error(_))),
        prueba('Limite vacio',
               integral_definida('x', '', 1, _, sin_resultado, error(_))),
        prueba('Limite que contiene x',
               integral_definida('x', 0, 'x+1', _, sin_resultado, error(_))),
        prueba('Expresion no valida',
               integral_definida('2x', 0, 1, sin_resultado, sin_resultado, error(_))),
        % --- Discontinuidades en el intervalo
        prueba('1/x en [-1, 1] (asintota en 0)',
               integral_definida('1/x', -1, 1, _, sin_resultado, error(_))),
        prueba('1/x en [0, 1] (no definida en el extremo)',
               integral_definida('1/x', 0, 1, _, sin_resultado, error(_))),
        prueba('x^-2 en [-1, 2]',
               integral_definida('x^-2', -1, 2, _, sin_resultado, error(_))),
        prueba('tan(x) en [0, 2] (asintota en pi/2)',
               integral_definida('tan(x)', 0, 2, _, sin_resultado, error(_))),
        prueba('x^0.5 en [-1, 1] (raiz de negativo)',
               integral_definida('x^0.5', -1, 1, _, sin_resultado, error(_))),
        prueba('1/x en [1, e] = 1 (sin discontinuidad)',
               (integral_definida('1/x', 1, e, _, V29, ok), cerca(V29, 1))),
        % --- Area geometrica
        prueba('Area de x en [-1, 1] = 1 (la integral da 0)',
               (area_bajo_curva('x', -1, 1, A30, ok), cerca(A30, 1))),
        prueba('Area de sin(x) en [0, 2*pi] = 4',
               (area_bajo_curva('sin(x)', 0, '2*pi', A31, ok), cerca(A31, 4))),
        prueba('Area de x^2 - 1 en [0, 2] = 2',
               (area_bajo_curva('x^2 - 1', 0, 2, A32, ok), cerca(A32, 2))),
        prueba('Area con discontinuidad devuelve error',
               area_bajo_curva('1/x', -1, 1, sin_resultado, error(_)))
    ],
    maplist(ejecutar_prueba_integrante3, Pruebas, Resultados),
    include(=(ok), Resultados, Correctas),
    length(Resultados, Total),
    length(Correctas, Exitos),
    format('--- Integrante 3: ~d de ~d pruebas correctas ---~n', [Exitos, Total]),
    Exitos =:= Total.

ejecutar_prueba_integrante3(prueba(Nombre, Consulta), Resultado) :-
    (   catch(once(call(Consulta)), _, fail)
    ->  Resultado = ok,
        format('  [OK] ~w~n', [Nombre])
    ;   Resultado = fallo,
        format('  [FALLO] ~w~n', [Nombre])
    ).

% Demostracion para la defensa: muestra el procedimiento paso a paso.
demo_integral(Texto, A, B) :-
    integral_definida(Texto, A, B, F, V, E),
    format('f(x)   = ~w~n', [Texto]),
    format('[a, b] = [~w, ~w]~n', [A, B]),
    (   E == ok
    ->  validar_intervalo(A, B, Va, Vb, _),
        evaluar_en(F, Vb, Fb), evaluar_en(F, Va, Fa),
        format('F(x)   = ~w~n', [F]),
        format('F(b)   = ~6f~nF(a)   = ~6f~n', [Fb, Fa]),
        format('F(b) - F(a) = ~6f~n', [V]),
        (   area_bajo_curva(Texto, A, B, Ar, ok)
        ->  format('Area geometrica = ~6f~n', [Ar])
        ;   true
        )
    ;   E = error(M),
        format('Error: ~w~n', [M])
    ).
