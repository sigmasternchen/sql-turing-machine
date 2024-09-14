CREATE TABLE input (
  input BYTEA
);

INSERT INTO input VALUES ('aabbbaa'::BYTEA || '\x00'::BYTEA);

CREATE TABLE program (
  state INT,
  read INT,
  next_state INT,
  write INT,
  move INT,
  accept BOOL DEFAULT false,
  reject BOOL DEFAULT false
);

INSERT INTO program VALUES 
  -- search right
  (000,        0  , 100,        0  , 0, false, false), -- input is empty; accept
  (000, ASCII('a'), 011,        0  , 1, false, false),
  (000, ASCII('b'), 016,        0  , 1, false, false),
  
  -- search right for 'a' 
  (011,        0  , 012,        0  , -1, false, false), -- end found
  (011, ASCII('a'), 011, ASCII('a'),  1, false, false),
  (011, ASCII('b'), 011, ASCII('b'),  1, false, false),
  
  -- search right for 'a': verify value
  (012,        0  , 100,        0  ,  0, false, false),
  (012, ASCII('a'), 001,        0  , -1, false, false),
  (012, ASCII('b'), 101,        0  ,  0, false, false), -- 'a' expected, 'b' found
  
  -- search right for 'b'
  (016,        0  , 017,        0  , -1, false, false), -- end found
  (016, ASCII('a'), 016, ASCII('a'),  1, false, false),
  (016, ASCII('b'), 016, ASCII('b'),  1, false, false),
  
  -- search right for 'b': verify value
  (017,        0  , 100,        0  ,  0, false, false),
  (017, ASCII('a'), 101,        0  ,  0, false, false), -- 'b' expected, 'a' found
  (017, ASCII('b'), 001,        0  , -1, false, false), 
  
  
  -- search left
  (001,        0  , 100,        0  ,  0, false, false), -- input is empty; accept
  (001, ASCII('a'), 021,        0  , -1, false, false),
  (001, ASCII('b'), 026,        0  , -1, false, false),
    
  -- search left for 'a' 
  (021,        0  , 022,        0  ,  1, false, false), -- end found
  (021, ASCII('a'), 021, ASCII('a'), -1, false, false),
  (021, ASCII('b'), 021, ASCII('b'), -1, false, false),
  
  -- search left for 'a': verify value
  (022,        0  , 100,        0  ,  0, false, false),
  (022, ASCII('a'), 000,        0  ,  1, false, false),
  (022, ASCII('b'), 101,        0  ,  0, false, false), -- 'a' expected, 'b' found
  
  -- search left for 'b'
  (026,        0  , 027,        0  ,  1, false, false), -- end found
  (026, ASCII('a'), 026, ASCII('a'), -1, false, false),
  (026, ASCII('b'), 026, ASCII('b'), -1, false, false),
  
  -- search left for 'b': verify value
  (027,        0  , 100,        0  ,  0, false, false),
  (027, ASCII('a'), 101,        0  ,  0, false, false), -- 'b' expected, 'a' found
  (027, ASCII('b'), 000,        0  ,  1, false, false), 
  
  
  -- accept state
  (100,        0  , 100,        0  ,  0, true, false),
  (100, ASCII('a'), 100,        0  ,  0, true, false),
  (100, ASCII('b'), 100,        0  ,  0, true, false),
  
  -- reject state
  (101,        0  , 101,        0  ,  0, false, true),
  (101, ASCII('a'), 101,        0  ,  0, false, true),
  (101, ASCII('b'), 101,        0  ,  0, false, true)
;


WITH RECURSIVE run_state (iteration, state, position, band, accept, reject) AS (
  SELECT 
    0, 000, 0 , input, false, false
  FROM input

  UNION ALL
  
  SELECT 
    run_state.iteration + 1,
    program.next_state,
    run_state.position + program.move,
    set_byte(run_state.band, run_state.position, program.write),
    program.accept,
    program.reject
  FROM run_state
  INNER JOIN program
    ON  program.state = run_state.state
    AND program.read = get_byte(run_state.band, run_state.position)
  WHERE 
        NOT run_state.accept 
    AND NOT run_state.reject
)
SELECT 
  CASE
    WHEN run.accept THEN 'Input was accepted in ' || run.iteration || ' iterations.'
    WHEN run.reject THEN 'Input was rejected in ' || run.iteration || ' iterations.'
    ELSE '[insert confused meme here]'
  END
FROM run_state AS run
WHERE 
     run.accept
  OR run.reject;
