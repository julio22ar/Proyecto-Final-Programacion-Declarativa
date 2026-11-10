/* ============================================================
   PROYECTO FINAL - PROGRAMACION DECLARATIVA - CICLO 02/2026
   Sistema de solucion de integrales

   INTEGRANTE 1: Integracion algebraica y validaciones
     - Reglas de integracion:  x^n,  u + v,  sin(x)
     - Formato de las expresiones que recibe Prolog
     - Validacion de la entrada (estructura y errores)
   ============================================================ */

:- encoding(utf8).

/* Todas las reglas de integracion del grupo usan el mismo predicado
   (formato visto en clase):

       s(Var, Funcion, Resultado)

   Var       -> variable respecto a la que se integra (siempre el atomo x)
   Funcion   -> expresion a integrar (ya validada y normalizada)
   Resultado -> primitiva, SIN la constante C

   Como cada integrante define clausulas de s/3 en su propio archivo,
   se declara multifile y discontiguous en todos los archivos. */
:- multifile s/3.
:- discontiguous s/3.


/* ============================================================
   PARTE 1. FORMATO DE LAS EXPRESIONES (contrato del grupo)
   ============================================================

   Variable de integracion : x   (minuscula)
   Constantes              : numeros enteros o decimales (2, -3, 0.5)
                             y las constantes pi y e
   Operadores              : +  -  *  /  ^  y el menos unario (-u)
   Funciones               : sin cos tan asin acos atan
                             sh cosh tanh arcsinh arccosh arctanh
   Agrupacion              : parentesis  ( )

   Ejemplos validos   : x^2 + sin(x)     3*x^4 - 2     2^x     sh(x)
   Ejemplos invalidos : 2x   sin x   sen(x)   X+1   y^2   x/0   (x+1
   ------------------------------------------------------------ */

% Funciones que el sistema reconoce (nombre en Prolog).
funcion_permitida(sin).
funcion_permitida(cos).
funcion_permitida(tan).
funcion_permitida(asin).
funcion_permitida(acos).
funcion_permitida(atan).
funcion_permitida(sh).        % seno hiperbolico, asi aparece en el enunciado
funcion_permitida(cosh).
funcion_permitida(tanh).
funcion_permitida(arcsinh).
funcion_permitida(arccosh).
funcion_permitida(arctanh).

% Constantes simbolicas aceptadas.
constante_simbolica(pi).
constante_simbolica(e).

% es_constante(+K): K es un numero o una constante simbolica.
% (Pueden usarlo los demas integrantes en sus reglas.)
es_constante(K) :- number(K), !.
es_constante(K) :- atom(K), constante_simbolica(K).

% no_depende_de(+X, +E): la expresion E no contiene la variable X.
% Sirve para reconocer constantes compuestas como 2*pi o 3^2.
no_depende_de(X, X) :- !, fail.
no_depende_de(_, E) :- atomic(E), !.
no_depende_de(X, E) :-
    compound(E),
    E =.. [_ | Args],
    forall(member(A, Args), no_depende_de(X, A)).


/* ============================================================
   PARTE 2. VALIDACION DE LA ENTRADA
   ============================================================

   Predicado principal para la interfaz / motor:

     validar_texto(+Texto, -Expr, -Estado)
        Texto  : la expresion tal como la escribe el usuario
                 (atomo o string), p. ej. 'x^2 + sin(x)'
        Expr   : termino de Prolog listo para integrar
        Estado : ok  |  error(Mensaje)

   Ejemplo:
     ?- validar_texto('x^2 + sin(x)', E, S).
     E = x^2+sin(x), S = ok.

     ?- validar_texto('2x', E, S).
     S = error('Error de sintaxis: revise operadores y parentesis (ej. escriba 2*x, no 2x)').
   ------------------------------------------------------------ */

validar_texto(Texto, Expr, Estado) :-
    texto_a_string(Texto, S0),
    (   texto_vacio(S0)
    ->  Expr = vacio,
        Estado = error('La expresion esta vacia')
    ;   preparar_texto(S0, S),
        leer_termino(S, T, Vars, Estado0),
        (   Estado0 \== ok
        ->  Expr = T, Estado = Estado0
        ;   Vars \== []
        ->  Expr = T, mensaje_variables(Vars, Estado)
        ;   validar_expresion(T, Estado1),
            (   Estado1 == ok
            ->  normalizar(T, Expr), Estado = ok
            ;   Expr = T, Estado = Estado1
            )
        )
    ).

% --- Conversion y limpieza del texto ---------------------------------

texto_a_string(T, S) :- string(T), !, S = T.
texto_a_string(T, S) :- atom(T), !, atom_string(T, S).
texto_a_string(T, S) :- is_list(T), !, string_codes(S, T).
texto_a_string(T, S) :- term_string(T, S).

texto_vacio(S) :- normalize_space(string(L), S), L == "".

% Ajustes para que la sintaxis de Prolog acepte la notacion comun:
%   "**"  -> "^"          (x**2 equivale a x^2)
%   "^-"  -> "^ -"        (x^-1: Prolog necesita un espacio)
preparar_texto(S0, S) :-
    reemplazar(S0, "**", "^", S1),
    reemplazar(S1, "^-", "^ -", S).

reemplazar(S0, Buscar, Poner, S) :-
    split_string_all(S0, Buscar, Partes),
    atomic_list_concat(Partes, Poner, A),
    atom_string(A, S).

split_string_all(S, Sep, Partes) :-
    (   sub_string(S, Antes, _, Despues, Sep)
    ->  sub_string(S, 0, Antes, _, P1),
        sub_string(S, _, Despues, 0, Resto),
        split_string_all(Resto, Sep, Ps),
        Partes = [P1 | Ps]
    ;   Partes = [S]
    ).

% --- Lectura del termino (detecta errores de sintaxis) ---------------

leer_termino(S, T, Vars, Estado) :-
    catch(( term_string(T, S, [variable_names(Vars)]),
            Estado = ok ),
          _Error,
          ( T = invalido, Vars = [],
            Estado = error('Error de sintaxis: revise operadores y parentesis (ej. escriba 2*x, no 2x)') )).

% Prolog lee como variables los nombres que empiezan con mayuscula o "_".
mensaje_variables(Vars, error(Msg)) :-
    findall(N, member(N = _, Vars), Nombres),
    atomic_list_concat(Nombres, ', ', Lista),
    format(atom(Msg),
           'Variable no permitida: ~w. Use solo x en minuscula', [Lista]).

% --- Validacion recursiva de la estructura ---------------------------
%
%   validar_expresion(+E, -Estado)    Estado = ok | error(Mensaje)
%   expresion_valida(+E)              exito si E cumple el formato
%
% Casos base : numeros, la variable x, constantes simbolicas.
% Casos recursivos : operadores y funciones -> se valida cada argumento.
% Se devuelve el PRIMER error encontrado.

expresion_valida(E) :- validar_expresion(E, ok).

validar_expresion(E, error('Expresion incompleta')) :- var(E), !.

% Casos base
validar_expresion(N, ok) :- number(N), !.
validar_expresion(x, ok) :- !.
validar_expresion(K, ok) :- atom(K), constante_simbolica(K), !.
validar_expresion(A, error(Msg)) :-
    atom(A), !,
    format(atom(Msg), 'Simbolo no reconocido: ~w (la variable debe ser x)', [A]).
validar_expresion(S, error('No se permiten textos entre comillas')) :-
    string(S), !.

% Casos especiales de error (se revisan antes que la regla general)
validar_expresion(_ / D, error('Division entre cero')) :-
    number(D), D =:= 0, !.
validar_expresion(B ^ P, error('Cero elevado a una potencia negativa')) :-
    number(B), B =:= 0, number(P), P < 0, !.

% Operadores binarios
validar_expresion(E, Estado) :-
    E =.. [Op, A, B],
    operador_binario(Op), !,
    validar_expresion(A, EA),
    (   EA == ok -> validar_expresion(B, Estado) ; Estado = EA ).

% Menos unario  (-u)
validar_expresion(-A, Estado) :- !,
    validar_expresion(A, Estado).
% Mas unario  (+u)
validar_expresion(+A, Estado) :- !,
    validar_expresion(A, Estado).

% Funciones de un argumento
validar_expresion(E, Estado) :-
    E =.. [F, A],
    funcion_permitida(F), !,
    validar_expresion(A, Estado).

% Cualquier otra cosa es un error
validar_expresion(E, error(Msg)) :-
    compound(E), !,
    compound_name_arity(E, F, N),
    (   N =:= 1
    ->  format(atom(Msg), 'Funcion no reconocida: ~w (ej. use sin, no sen)', [F])
    ;   format(atom(Msg), 'Operador o funcion no reconocida: ~w con ~w argumentos', [F, N])
    ).
validar_expresion(_, error('Expresion no valida')).

operador_binario(+).
operador_binario(-).
operador_binario(*).
operador_binario(/).
operador_binario(^).

% --- Normalizacion ---------------------------------------------------
% Deja la expresion en una forma uniforme para el motor:
%   +u      -> u
%   -(N)    -> numero negativo   ( - 1  ->  -1 )
normalizar(E, E) :- var(E), !.
normalizar(E, E) :- atomic(E), !.
normalizar(+A, R) :- !, normalizar(A, R).
normalizar(-A, R) :- !,
    normalizar(A, RA),
    (   number(RA) -> R is -RA ; R = -RA ).
normalizar(E, R) :-
    E =.. [F | Args],
    maplist(normalizar, Args, RArgs),
    R =.. [F | RArgs].


/* ============================================================
   PARTE 3. REGLAS DE INTEGRACION DEL INTEGRANTE 1
   ============================================================ */

% --- 1) Potencia:  ∫ x^n dx = x^(n+1) / (n+1),   n ≠ -1   (caso base)
s(X, X^N, X^N1 / N1) :-
    number(N),
    N =\= -1,
    N1 is N + 1.

% Caso especial n = -1:  ∫ x^(-1) dx = ln|x|   (caso base)
s(X, X^N, log(abs(X))) :-
    number(N),
    N =:= -1.

% Misma integral escrita como division:  ∫ 1/x dx = ln|x|   (caso base)
s(X, 1/X, log(abs(X))).

% --- 2) Suma:  ∫ (u + v) dx = ∫ u dx + ∫ v dx   (caso recursivo)
% Se integra cada sumando llamando otra vez a s/3, por lo que u y v
% pueden ser cualquier funcion que sepa integrar el grupo
% (incluso otras sumas: x^2 + sin(x) + x^3).
s(X, U + V, RU + RV) :-
    s(X, U, RU),
    s(X, V, RV).

% --- 3) Seno:  ∫ sin(x) dx = -cos(x)   (caso base)
s(X, sin(X), -cos(X)).


/* ============================================================
   PARTE 4. PRUEBAS DEL INTEGRANTE 1
   Ejecutar:   ?- probar_integrante1.
   ============================================================ */

probar_integrante1 :-
    writeln('--- Validaciones ---'),
    forall(member(T, [ 'x^2 + sin(x)', '3*x^4 - 2', 'x^-1', 'x**3',
                       '2x', 'sin x', 'sen(x)', 'X + 1', 'y^2',
                       'x/0', '(x+1', '', 'cos(x) + sh(x)' ]),
           ( validar_texto(T, E, S),
             format('  ~q~t~22| -> ~w   ~w~n', [T, S, E]) )),
    writeln('--- Integrales (reglas del integrante 1) ---'),
    forall(member(F, [ x^2, x^0, x^(-1), x^(-3), x^0.5, 1/x,
                       sin(x), x^2 + sin(x), x^3 + x^2 + sin(x) ]),
           (   s(x, F, R)
           ->  format('  Integral de ~w dx = ~w + C~n', [F, R])
           ;   format('  Integral de ~w dx : no hay regla todavia~n', [F])
           )).
