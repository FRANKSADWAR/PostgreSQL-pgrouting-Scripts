CREATE OR REPLACE FUNCTION modified_dijkstra (
    departure BIGINT, destination BIGINT,
    OUT seq INTEGER, OUT path_seq INTEGER,
    OUT node BIGINT, OUT edge BIGINT,
    OUT cost FLOAT, OUT agg_cost FLOAT )
RETURNS SETOF RECORD AS
$BODY$

SELECT * FROM pgr_dijkstra(
    $$

    WITH
    edges_to_expand AS (
        SELECT id
        FROM searoutes
        WHERE ARRAY[$$ || departure || $$]::BIGINT[] <@ contracted_vertices
           OR ARRAY[$$ || destination || $$]::BIGINT[] <@ contracted_vertices
    ),

    vertices_to_expand AS (

        SELECT id
        FROM searoutes_vertices_pgr
        WHERE ARRAY[$$ || departure || $$]::BIGINT[] <@ contracted_vertices
           OR ARRAY[$$ || destination || $$]::BIGINT[] <@ contracted_vertices

    ),

    vertices_in_graph AS (
        SELECT id
        FROM searoutes_vertices_pgr
        WHERE is_contracted = false

        UNION

        SELECT unnest(contracted_vertices)
        FROM searoutes
        WHERE id IN (SELECT id FROM edges_to_expand)

        UNION

        SELECT unnest(contracted_vertices)
        FROM searoutes_vertices_pgr
        WHERE id IN (SELECT id FROM vertices_to_expand)
    )

    SELECT id, source, target, cost, reverse_cost
    FROM searoutes
    WHERE source IN (SELECT * FROM vertices_in_graph)
    AND target IN (SELECT * FROM vertices_in_graph)
    $$,
    departure, destination, false);
$BODY$
LANGUAGE SQL VOLATILE;