--Andmebaasisüsteem: PostgreSQL 9.2.1
--Autor: Martin Kurgi 111705IABM
-- Kuupäev: 2012-11-9


DROP TABLE IF EXISTS person_book CASCADE;
DROP TABLE IF EXISTS book_stats;
DROP VIEW IF EXISTS vwPercent;
DROP FUNCTION IF EXISTS buyer_count(integer, integer);
DROP FUNCTION IF EXISTS buyer_count_int(integer, integer);
DROP FUNCTION IF EXISTS buyer_count_single(integer);

--Tabel CSV andmete hoidmiseks
CREATE TABLE IF NOT EXISTS person_book(
person_book_id SERIAL,
person_id integer,
book_id integer,
PRIMARY KEY(person_book_id));

CREATE INDEX book_id_idx ON person_book(book_id);

--Andmete sisestamine CSV failist andmebaasi
COPY person_book(person_id, book_id) FROM '/tmp/data.txt' DELIMITERS ',' CSV HEADER;

--Tabel raamatute statistika jaoks (Ülesanne 2)
CREATE TABLE IF NOT EXISTS book_stats(
book_stats_id SERIAL,
book1 integer,
book2 integer,
buyer_count integer,
PRIMARY KEY(book_stats_id));





--Ülesande 1 lahendus
---------------------
CREATE OR REPLACE FUNCTION buyer_count(book_id_1 integer, book_id_2 integer)
  RETURNS text 
  AS
$$
  SELECT 'Raamatuid ' || $1 || ' ja ' || $2 || ' on korraga ostnud ' || COUNT(DISTINCT person_id) || ' inimest'
  FROM
  (
    SELECT person_id  FROM person_book where book_id=$1
    INTERSECT
    SELECT person_id  FROM person_book where book_id=$2
  ) t;
$$
LANGUAGE SQL IMMUTABLE STRICT;



--Abifunktsioon ülesande 2 jaoks. Tagastab ostjate arvu arvulise väärtuse ette antud 2 raamatu kohta
CREATE OR REPLACE FUNCTION buyer_count_int(book_id_1 integer, book_id_2 integer)
  RETURNS bigint
  AS
$$
  SELECT COUNT(DISTINCT person_id)
  FROM
  (
    SELECT person_id  FROM person_book where book_id=$1
    INTERSECT
    SELECT person_id  FROM person_book where book_id=$2
  ) t;
$$
LANGUAGE SQL IMMUTABLE STRICT;


--Ülesande 2 lahendus
---------------------
WITH books AS 
(
  --alampäring kõigi raamatute leidmiseks
  SELECT distinct book_id from person_book 
  --Kuna soovime lahendust saada mõistliku aja jooksul, siis võtame alamhulga kõigist raamatutest
  where book_id between 0 and 10
), stats AS
(
  SELECT T1.book_id as book1, T2.book_id as book2, buyer_count_int(T1.book_id, T2.book_id) AS buyer_count 
  FROM books AS T1 CROSS JOIN books AS T2 
  WHERE T1.book_id != T2.book_id 
  and buyer_count_int(T1.book_id, T2.book_id) > 0
  order by T1.book_id, T2.book_id asc
)
INSERT INTO book_stats(book1, book2, buyer_count)
SELECT book1, book2, buyer_count from stats;




--Abifunktsioon ülesande 3 jaoks. Tagastab ostjate arvu arvulise väärtuse ette antud 1 raamatu kohta
CREATE OR REPLACE FUNCTION buyer_count_single(book_id_1 integer)
  RETURNS bigint
  AS
$$
  SELECT COUNT(DISTINCT person_id)  FROM person_book where book_id=$1;
$$
LANGUAGE SQL IMMUTABLE STRICT;

--Ülesande 3 lahendus
---------------------
CREATE OR REPLACE VIEW vwPercent AS 
SELECT book1, book2, round((100*buyer_count_int(book1, book2)::numeric(7,2)/buyer_count_single(book1)::numeric(7,2)),2)||'%' as percent
FROM book_stats;