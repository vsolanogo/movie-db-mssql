-- 1) Сума касових зборів за жанрами фільмів
SELECT Sum(Movie.BoxOffice) AS BO, Genre.Name 
FROM Movie 
INNER JOIN Genre 
	ON Movie.GenreKey = Genre.GenreKey 
GROUP BY Genre.Name
ORDER BY BO DESC;

-- 2) Ім’я персонажу, за якого було отримано найменший гонорар
SELECT CharacterName AS [Lowest Fee]
FROM Cast 
WHERE Fee=
	(SELECT MIN(FEE) 
	FROM Cast);

-- 3) Ім’я актора, його вік, стать та сума гонорарів за всі фільми
SELECT Actor.Name [Actor], DATEDIFF(yy, Actor.BirthDate, GETDATE()) Age , Actor.Sex , SUM(Cast.Fee) Fee
FROM Actor 
JOIN Cast 
	ON Actor.ActorId=Cast.ActorId 
GROUP BY Actor.Name, Actor.BirthDate, Actor.Sex
ORDER BY Fee DESC;

-- 4) Суми гонорарів за чоловічі та жіночі ролі
SELECT Actor.Sex, SUM(Cast.Fee) Fee
FROM Actor 
JOIN Cast 
	ON Actor.ActorId = Cast.ActorId 
GROUP BY Actor.Sex;

-- 5) Назва фільму та ім’я актора, що отримав найбільший гонорар в ньому. Якщо акторів для фільму в базі немає – залишити поле пустим (null)
SELECT M.Name Movie, A.Name [Most paid actor]
FROM Cast C 
JOIN Actor A 
	ON A.ActorId = C.ActorId
RIGHT OUTER JOIN Movie M 
	ON M.MovieId = C.MovieId
WHERE C.Fee = 
	(SELECT MAX(Fee)
	FROM Cast C2
	WHERE M.MovieId = C2.MovieId);

-- 6) Назви, дати прем’єри та касові збори фільмів, середня оцінка яких більше 6
SELECT M.Name, M.PremiereDate, M.BoxOffice
FROM Movie M 
JOIN Feedback F 
	ON M.MovieId = F.MovieId
WHERE F.Rank > 6

-- 7) Імена персонажів та акторів, що їх зіграли, у фільмах пізніше 2000 року
SELECT C.CharacterName, A.Name [Actor]
FROM Cast C 
JOIN Actor A
	ON C.ActorId = A.ActorId
JOIN Movie M 
	ON M.MovieId = C.MovieId 
	AND M.PremiereDate > '2000'

-- 8) Ім’я актора та його найприбутковіша роль. Якщо такої нема – вивести «no data» в полях ролі

--1 найприбутковіша роль без суми її гонорарів
SELECT A.Name, ISNULL(P.CharacterName, 'no data') [Most paid character]
FROM Actor A
LEFT OUTER JOIN
	(SELECT DISTINCT C.ActorId, C.CharacterName, C.Fee
	FROM Cast C
	WHERE Fee = (SELECT MAX(C2.Fee) 
				FROM Cast C2 
				WHERE C2.ActorId = C.ActorId)
	) AS P
ON A.ActorId = P.ActorId;

--2 з сумою гонорарів однакової ролі
WITH P 
AS 
(
	SELECT DISTINCT C.ActorId, C.CharacterName, SUM(C.Fee) Fee
	FROM Cast C
	WHERE Fee = 
		(SELECT MAX(C2.Fee) 
		FROM Cast C2 
		WHERE C2.ActorId = C.ActorId)
	GROUP BY C.ActorId, C.CharacterName
)

SELECT A.Name, ISNULL(P2.CharacterName, 'no data') [Most paid character]
FROM Actor A
LEFT OUTER JOIN 
	(SELECT P.ActorId ActorId,P.CharacterName CharacterName, P.Fee Fee
	FROM P 
	WHERE P.Fee = (SELECT MAX(P2.Fee) 
				FROM P P2 
				WHERE P2.ActorId = P.ActorId)
	) AS P2
ON A.ActorId = P2.ActorId;


-- 9) Ім’я актора, та його гонорар по кожного фільму. Сортувати по величині суми гонорару
SELECT A.Name [Actor name], M.Name [Movie name], C.Fee
FROM Movie M 
JOIN Cast C
	ON M.MovieId = C.MovieId		
JOIN Actor A
	ON A.ActorId = C.ActorId
ORDER BY [Actor name],  Fee DESC;

-- 10) Всі фільми, касові збори яких в 10 раз перевищили суму гонорарів акторам
WITH SumFee
AS
(
	SELECT SUM(Fee) Fee, MovieId
	FROM Cast
	GROUP BY MovieId
)

SELECT M.Name
FROM Movie M
WHERE M.BoxOffice > 10 * (SELECT S.Fee 
						FROM SumFee S 
						WHERE S.MovieId = M.MovieId);

						
-- 11) Імена акторів, їхній вік та назви фільмів, в яких вони зіграли свої 
-- перші ролі (згадані в базі)
WITH ActorMovie
AS
(
SELECT C.ActorId, M.MovieId, M.PremiereDate
FROM Cast C
JOIN Movie M
	ON C.MovieId = M.MovieId
)

SELECT  A.Name, DATEDIFF(yy, A.BirthDate, GETDATE()) Age, M.Name [First entry]
FROM Actor A, Movie M
WHERE M.PremiereDate = (SELECT MIN(AM.PremiereDate) 
						FROM ActorMovie AM 
						WHERE A.ActorId = AM.ActorId);
						
-- 12) всі назви фільмів, їхні описи, день прем’єри та загальний гонорар акторів цього фільму, який
-- повинен бути більше 400 000. посортувати за гонораром.
WITH P
AS
(
SELECT DISTINCT M.Name, M.Description, M.PremiereDate, SUM(C.Fee) OVER(PARTITION BY M.Name) Fee
FROM Movie M
JOIN Cast C
	ON M.MovieId = C.MovieId
)

SELECT * 
FROM P 
WHERE Fee > 400000
ORDER BY Fee DESC;

go

SELECT DISTINCT M.Name, M.Description, M.PremiereDate, SUM(C.Fee) Fee
FROM Movie M
JOIN Cast C
	ON M.MovieId = C.MovieId
GROUP BY M.Name, M.Description, M.PremiereDate
HAVING SUM(C.Fee) > 400000
ORDER BY SUM(C.Fee) DESC

-- 13) Прибуток фільму (касові збори - гонорари акторам) та його назва. Вивести рядок підсумків. Відсортувати за прибутком
WITH P
AS
(
SELECT M.BoxOffice - SUM(C.Fee) Income, M.Name
FROM Movie M
JOIN Cast C
	ON M.MovieId = C.MovieId
GROUP BY M.BoxOffice, M.Name 
)
SELECT * 
FROM P
UNION ALL
SELECT SUM(P.Income), 'Total'
FROM P
ORDER BY Income DESC;

-- 14) Назву фільму, касові збори, дату прем’єри, жанр та 1 коментар з найвищою оцінкою. Якщо оцінки чи коментаря нема - писати “no comments found”
SELECT M.Name, M.BoxOffice, M.PremiereDate, G.Name, ISNULL(F.Text, 'no comments found') Text
FROM Movie M
JOIN Genre G
	ON M.GenreKey = G.GenreKey
LEFT OUTER JOIN Feedback F
	ON F.MovieId = M.MovieId;
	
-- 15) Назва фільму, дата прем’єри, жанр та середній гонорар акторам в цьому фільмі
SELECT M.Name, M.PremiereDate, G.Name, AVG(C.Fee) [Avg Fee]
FROM Movie M
JOIN Genre G
	ON M.GenreKey = G.GenreKey
JOIN Cast C
	ON C.MovieId = M.MovieId
GROUP BY M.NAME, M.PremiereDate, G.Name;

-- 16) Статистика по всім жанрам, яка включає: кількість фільмів, загальна сума касових зборів, кількість залучених акторів.
WITH MovieActors
AS
(
SELECT C.MovieId, COUNT(C.ActorId) ActorsCount
FROM Cast C
GROUP BY C.MovieId
)

SELECT G.Name Genre, COUNT(M.MovieId) Movies, SUM(M.BoxOffice) BoxOffice, SUM(P.ActorsCount) Actors
FROM GENRE G
JOIN Movie M
	ON M.GenreKey = G.GenreKey
JOIN MovieActors P 
	ON M.MovieId= P.MovieId
GROUP BY G.Name;

--17) Імена акторів, які знімались в жанрах “Horror” і “Thriller”
SELECT DISTINCT A.Name 
FROM Cast C
JOIN Movie M 
	ON M.MovieId = C.MovieId
JOIN Genre G
	ON G.GenreKey = M.GenreKey
JOIN Actor A
	ON A.ActorId = C.ActorId
WHERE G.Name = 'Horror' 

INTERSECT

SELECT DISTINCT A.Name 
FROM Cast C
JOIN Movie M 
	ON M.MovieId = C.MovieId
JOIN Genre G
	ON G.GenreKey = M.GenreKey
JOIN Actor A
	ON A.ActorId = C.ActorId
WHERE G.Name = 'Thriller';

-- 18) Найпопулярніші жанри для акторів та актрис
WITH Popularity
AS
(
SELECT G.Name Genre, A.Sex, Count(G.Name) GenreCount
FROM Actor A
JOIN Cast C
	ON C.ActorId = A.ActorId
JOIN Movie M
	ON M.MovieId = C.MovieId
JOIN Genre G 
	ON M.GenreKey = G.GenreKey
GROUP BY A.Sex, G.Name
)

SELECT Genre, [male] [Male most pop],  [female] [Female most pop]
FROM Popularity
PIVOT
(
	MAX(GenreCount)
	FOR Sex IN
	([male], [female])
) Pivoting
ORDER BY Male DESC, Female;

-- 19) Імена акторів, які грали у фільмах жанру “Thriller”, але не грали в “Sci-Fi”
SELECT A.Name
FROM Actor A
JOIN Cast C
	ON A.ActorId = C.ActorId
JOIN Movie M
	ON M.MovieId = C.MovieId
JOIN Genre G
	ON G.GenreKey = M.GenreKey
WHERE G.Name = 'Thriller'

EXCEPT

SELECT A.Name
FROM Actor A
JOIN Cast C
	ON A.ActorId = C.ActorId
JOIN Movie M
	ON M.MovieId = C.MovieId
JOIN Genre G
	ON G.GenreKey = M.GenreKey
WHERE G.Name = 'Sci-Fi';

-- 20) Кількість акторів кожної статі. Транспонувати результат.
WITH PivotData
AS
(
SELECT A.Sex, COUNT(A.Name) [Count]
FROM Actor A
GROUP BY A.Sex
)

SELECT [Male], [Female]
FROM PivotData
PIVOT
( MAX(Count)
FOR Sex
IN ([Male], [Female])
) Pivoted

