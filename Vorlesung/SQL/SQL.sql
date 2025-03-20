-------------------------------------------------
--- Szenario: Basic-SQLs
-------------------------------------------------

---------------------------------------------------------------------------------


SELECT * FROM student; -- einfache Abfrage
select Name, Vorname from student; -- Spalten einschränken
select count(*) from student; -- Datensätze zählen
select Name, Vorname from student where Name = 'Shaine'; -- Selektieren
select distinct name from student where Name = 'Shaine'; -- Doppelgänger eliminieren
select name from student where Name = 'Shaine' and VORNAME = 'Lanita'; -- Selektieren mit AND NOT OR
select * from student where FB IN (1,2); -- Vergleich
select * from student where FB BETWEEN 1 And 3;
select * from student where NAME like 'l%';
select * from student where NAME like 'lo%';
select * from student where NAME like 'lor%';
select * from student where NAME like 'lor%' and Vorname like '%d';

SELECT * FROM student as s
join fachbereich fb on fb.FB = s.FB;

SELECT s.NAME, fb.Bezeichnung FROM student as s
join fachbereich fb on fb.FB = s.FB;

SELECT s.NAME, fb.Bezeichnung, fb.FB FROM student as s
join fachbereich fb on fb.FB = s.FB
where fb.FB > 3 and s.Name like '%lil%';

select * from KLAUSUR k
join STUDENT s on
k.MATNR = s.MATNR
join FACHBEREICH fb on
fb.FB = s.FB

-- -- noch ein Join

SELECT s.FB, count(*) FROM student s group by s.FB; -- Gruppieren

SELECT max(FB) FROM student; -- Aggregatfunktionen
SELECT min(FB) FROM student ;
SELECT avg(FB) FROM student ;
SELECT sum(FB) FROM student ;
SELECT count(FB) FROM student;

SELECT fb.FB, fb.BEZEICHNUNG, count(*) FROM student as s -- Gruppieren mit Join
join fachbereich fb on fb.FB = s.FB
group by fb.FB;

SELECT fb.FB, fb.BEZEICHNUNG, count(*) FROM student as s -- Gruppieren mit Join + Having
join fachbereich fb on fb.FB = s.FB
group by fb.FB
having count(*) > 100;

SELECT fb.FB, fb.BEZEICHNUNG, count(*) FROM student as s -- Gruppieren mit Join + Having + Where
join fachbereich fb on fb.FB = s.FB
where s.NAME like 'lo%'
group by fb.FB
having count(*) > 3;

SELECT * FROM student order by NAME DESC; -- einfache Sortierung

SELECT fb.FB, fb.BEZEICHNUNG, count(*) FROM student as s -- Ergebnisse sortieren
join fachbereich fb on fb.FB = s.FB
group by fb.FB
order by count(*) DESC;

SELECT fb.FB, fb.BEZEICHNUNG, count(*) FROM student as s -- Ergebnisse sortieren
join fachbereich fb on fb.FB = s.FB
group by fb.FB
order by count(*) DESC, fb.BEZEICHNUNG;

SELECT fb.FB, fb.BEZEICHNUNG, count(*) FROM student as s -- Ergebnisse sortieren
join fachbereich fb on fb.FB = s.FB
group by fb.FB
order by fb.BEZEICHNUNG;

SELECT * FROM student order by NAME DESC LIMIT 10; -- Ergebnisse limitieren

SELECT * FROM student s where s.FB= 1 union SELECT * FROM student s where s.FB= 2; -- Abfragen kombinieren
-- alternativ:-
SELECT * FROM student s where s.FB= 1 OR s.FB= 2;

select * from student where MATNR = (select round(avg(MATNR),0) from student) -- geschachtelt/Kombination


select s.MATNR, s.NAME from STUDENT s where s.MATNR = (select MATNR from KLAUSUR k where k.RESULTAT =4.0) -- Subqueries
select s.Name FROM STUDENT s where s.MATNR = any (select MATNR from KLAUSUR k where k.RESULTAT = 4.0); -- 335
select count(*) FROM STUDENT s where s.MATNR = any (select MATNR from KLAUSUR k where k.RESULTAT = 4.0); -- 335

select COUNT(DISTINCT MATNR) from KLAUSUR k where k.RESULTAT =4.0; -- 335
select COUNT(MATNR) from KLAUSUR k where k.RESULTAT =4.0;  -- 389
--als Join
SELECT count(*) from STUDENT s inner join KLAUSUR k on s.MATNR = k.MATNR
where k.RESULTAT = 4.0 -- 389
SELECT count(DISTINCT s.MATNR) from STUDENT s inner join KLAUSUR k on s.MATNR = k.MATNR
where k.RESULTAT = 4.0 -- 335

select s.MATNR, s.NAME from STUDENT s where s.MATNR IN (select MATNR from KLAUSUR k where k.RESULTAT >4)
select s.MATNR, s.NAME from STUDENT s where s.MATNR = ANY (select MATNR from KLAUSUR k where k.RESULTAT >2.0) -- irgend ein Wert der > 2
select s.MATNR, s.NAME from STUDENT s where s.MATNR = ALL (select MATNR from KLAUSUR k where k.RESULTAT >2.0) -- true, wenn alle Werte > 2 (also: false)


--- Zeichkettenoperationen:
select
s.MATNR, s.NAME, upper(s.name), replace(s.Name, s.name, 'HALLO')
from STUDENT s limit 10

--- Datumoperationen
select
s.MATNR, s.NAME, s.BIRTHDAY, day(s.BIRTHDAY), date_add(s.BIRTHDAY, INTERVAL 10 DAY)
from STUDENT s limit 10



-----updates:

update student set NAME = 'Update' where MATNR = 1000
update student set NAME = 'Update' where MATNR IN (1022, 1028)


update student s1, (SELECT * from fachbereich fb where fb.FB = 2) as s2
set s1.NAME = 'verknüpft'
where s1.FB = s2.FB


--- delete:
delete from student where MATNR =  1004
delete from student where MATNR Between 1010 and 1030;
delete from student where MATNR Between 1040 and 1060 LIMIT 5


------------------------------------------------------------------------------


