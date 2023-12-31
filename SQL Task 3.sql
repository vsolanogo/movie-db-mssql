-- 1)	Вставити новий фільм типу camedy (The Boss (2016), 29 000 000, 2016-04-28)

INSERT INTO MOVIE (Name, PremiereDate, BoxOffice, GenreKey)
VALUES (N'The Boss(2016)',N'20160428', 29000000, 
(SELECT G.GenreKey 
FROM Genre G 
WHERE G.Name =N'Comedy')
);

--2) Добавити акторів Brad Pitt, Cate Blanchett, Uma Thurman, Morgan Freeman. Назва ролі як перше слово з Актора назви, з ціною кодного 10000

INSERT dbo.Cast (ActorId, MovieId, CharacterName, Fee)
SELECT A.ActorId, M.MovieId, substring(A.Name, 1 , charindex(N' ',A.Name) -1), 10000
FROM Actor A, Movie M
WHERE M.Name = 'The Boss (2016)'
	AND A.Name IN (N'Brad Pitt', N'Cate Blanchett', N'Uma Thurman', N'Morgan Freeman');
	
-- 3) Добавити опис до цього фільму

UPDATE Movie
SET Description = N'American comedy film'
WHERE Name = N'The Boss (2016)';

-- 4) Поновити гонорари акторів для цього фільму: для жінок в два рази більше, а чоловіків в 2.5

UPDATE C
SET C.Fee *= 
	CASE A.Sex
	WHEN 'Female' THEN 2
	WHEN 'Male' THEN 2.5
	END
FROM Cast C
JOIN Actor A
ON A.ActorId = C.ActorId
WHERE MovieId = (SELECT M.MovieId 
				From Movie M 
				Where M.Name = N'The Boss (2016)')
				
-- 5) Добавити feedback до цього фільму. Кожний актора з бази має зробити опис. Текст назва актора + рік народження. Рейт - місяць народження актора.

INSERT Feedback (MovieId, Rank, Text)
SELECT M.MovieId, 
CASE 
	WHEN MONTH(A.BirthDate) > 10 THEN 10
	ELSE MONTH(A.BirthDate)
END
, A.Name +N' ' + CAST(YEAR(A.BirthDate) AS nvarchar)
	
FROM Movie M
JOIN Cast C
	ON M.MovieId = C.MovieId
JOIN Actor A
	ON A.ActorId = C.ActorId
WHERE M.MovieId = (SELECT M2.MovieId
				FROM Movie M2
				WHERE M2.Name = N'The Boss (2016)')

-- 6) Видалити всі feedbacks для цього фільму, якщо рейт більше рівне 10
DELETE FROM Feedback
WHERE MovieId = (SELECT M.MovieId FROM Movie M WHERE M.Name=N'The Boss (2016)')
	AND Rank >= 10;

	
-- 7) Створити представлення: Всі назви фільмів, їхні описи, день прем’єри та актори 

DECLARE @Counter			int,
		@Actors				nvarchar(500),
		@TempString			nvarchar(50),
		@CurrentMovie		nvarchar(100),
		@MoviesCount		int,
		@MovieIterator		int

IF OBJECT_ID('ActorsVarTable_ForView', 'U') IS NOT NULL
DROP TABLE ActorsVarTable_ForView;

CREATE TABLE ActorsVarTable_ForView		
		(
			Movie			nvarchar(100),
			Description	nvarchar(500),
			PremiereDate	date,
			Actors			nvarchar(500)
		)


SELECT @MovieIterator = 0

SELECT @MoviesCount = 
(SELECT  COUNT(DISTINCT M.Name)
FROM Movie M
JOIN Cast C
	ON M.MovieId = C.MovieId
JOIN Actor A
	ON A.ActorId = C.ActorId)

WHILE (@MovieIterator < @MoviesCount)
BEGIN
	SELECT @CurrentMovie =
	(SELECT  DISTINCT M.Name
	FROM Movie M
	JOIN Cast C
		ON M.MovieId = C.MovieId
	JOIN Actor A
		ON A.ActorId = C.ActorId
	ORDER BY M.Name
	OFFSET @MovieIterator ROWS FETCH NEXT 1 ROWS ONLY)

	DECLARE TheCursor CURSOR
	GLOBAL
	FOR
		SELECT A.Name
		FROM Movie M
		JOIN Cast C
			ON M.MovieId = C.MovieId
		JOIN Actor A
			ON A.ActorId = C.ActorId 
		WHERE M.Name = @CurrentMovie

	SELECT @Counter = 1
	OPEN TheCursor 
	FETCH NEXT FROM TheCursor INTO @Actors

	WHILE(@Counter <= 20) AND (@@FETCH_STATUS=0)
	BEGIN
		SELECT @Counter = @Counter + 1	
		FETCH NEXT FROM TheCursor INTO @TempString	
		IF (@@FETCH_STATUS=0)
		SELECT @Actors = (@Actors + N', ' + @TempString )
	END
	CLOSE TheCursor
	DEALLOCATE TheCursor  
	
	INSERT INTO ActorsVarTable_ForView (Movie, Description, PremiereDate, Actors)
	SELECT DISTINCT M.Name Movie, M.Description, M.PremiereDate, @Actors Actors
	FROM Movie M
	JOIN Cast C
		ON M.MovieId = C.MovieId
	JOIN Actor A
		ON A.ActorId = C.ActorId 	
		WHERE M.Name = @CurrentMovie

	SELECT @MovieIterator = @MovieIterator +1
END 

IF OBJECT_ID('MoviesInfo_vw', 'V') IS NOT NULL
DROP VIEW MoviesInfo_vw;
GO
CREATE VIEW MoviesInfo_vw
AS 
	SELECT * 
	FROM ActorsVarTable_ForView 
GO

SELECT * FROM MoviesInfo_vw ;

-- 8) Створити представлення: Жанри та актори

DECLARE @Counter			int,
		@Actors				nvarchar(500),
		@TempString			nvarchar(50),
		@CurrentGenre		nvarchar(100),
		@GenresCount		int,
		@GenreIterator		int

IF OBJECT_ID('GenresActors_ForView', 'U') IS NOT NULL
DROP TABLE GenresActors_ForView;
CREATE TABLE GenresActors_ForView		
		(
			Genre			nvarchar(100),
			Actors			nvarchar(500)
		)


SELECT @GenreIterator = 0

SELECT @GenresCount = 
(SELECT DISTINCT COUNT(G.Name)
FROM Actor A
JOIN Cast C
	ON A.ActorId = C.ActorId
JOIN Movie M
	ON M.MovieId = C.MovieId
JOIN Genre G 
	ON G.GenreKey = M.GenreKey
)

WHILE (@GenreIterator < @GenresCount)
BEGIN
	SELECT @CurrentGenre =
	(SELECT DISTINCT G.Name
	FROM Actor A
	JOIN Cast C
		ON A.ActorId = C.ActorId
	JOIN Movie M
		ON M.MovieId = C.MovieId
	JOIN Genre G 
		ON G.GenreKey = M.GenreKey
	ORDER BY G.Name
	OFFSET @GenreIterator ROWS FETCH NEXT 1 ROWS ONLY)

	DECLARE TheCursor CURSOR
	GLOBAL
	FOR
		SELECT A.Name
		FROM Actor A
		JOIN Cast C
			ON A.ActorId = C.ActorId
		JOIN Movie M
			ON M.MovieId = C.MovieId
		JOIN Genre G 
			ON G.GenreKey = M.GenreKey	 
		WHERE G.Name = @CurrentGenre

	SELECT @Counter = 1
	OPEN TheCursor 
	FETCH NEXT FROM TheCursor INTO @Actors

	WHILE(@Counter <= 20) AND (@@FETCH_STATUS=0)
	BEGIN
		SELECT @Counter = @Counter + 1	
		FETCH NEXT FROM TheCursor INTO @TempString	
		IF (@@FETCH_STATUS=0)
		SELECT @Actors = (@Actors + N', ' + @TempString ) 
	END
	CLOSE TheCursor
	DEALLOCATE TheCursor 
	
	INSERT INTO GenresActors_ForView (Genre, Actors)
	SELECT DISTINCT G.Name, @Actors Actors
	FROM Actor A
	JOIN Cast C
		ON A.ActorId = C.ActorId
	JOIN Movie M
		ON M.MovieId = C.MovieId
	JOIN Genre G 
		ON G.GenreKey = M.GenreKey	
	WHERE G.Name = @CurrentGenre

	SELECT @GenreIterator = @GenreIterator +1
END 

IF OBJECT_ID('GenresActors_vw', 'V') IS NOT NULL
DROP VIEW GenresActors_vw;
GO
CREATE VIEW GenresActors_vw
AS 
	SELECT * 
	FROM GenresActors_ForView 
GO

SELECT * FROM GenresActors_vw ;

-- 9) Створити представлення: Назви фільму та всі коментарі

DECLARE @Counter			int,
		@Comments			nvarchar(500),
		@TempString			nvarchar(50),
		@CurrentMovie		nvarchar(100),
		@MoviesCount		int,
		@MovieIterator		int

IF OBJECT_ID('MoviesComments_ForView', 'U') IS NOT NULL
DROP TABLE MoviesComments_ForView;
CREATE TABLE MoviesComments_ForView		
		(
			Movie			nvarchar(100),
			Comments		nvarchar(500)
		)


SELECT @MovieIterator = 0

SELECT @MoviesCount = 
(SELECT COUNT(DISTINCT M.Name)
FROM Movie M
JOIN Feedback F
	ON M.MovieId = F.MovieId
)

WHILE (@MovieIterator < @MoviesCount)
BEGIN
	SELECT @CurrentMovie =
	(SELECT DISTINCT M.Name
	FROM Movie M
	JOIN Feedback F
		ON M.MovieId = F.MovieId
	ORDER BY M.Name
	OFFSET @MovieIterator ROWS FETCH NEXT 1 ROWS ONLY)

	DECLARE TheCursor CURSOR
	GLOBAL
	FOR
		SELECT DISTINCT F.Text
		FROM Movie M
		JOIN Feedback F
			ON M.MovieId = F.MovieId  
		WHERE M.Name = @CurrentMovie

	SELECT @Counter = 1
	OPEN TheCursor 
	FETCH NEXT FROM TheCursor INTO @Comments

	WHILE(@Counter <= 20) AND (@@FETCH_STATUS=0)
	BEGIN
		SELECT @Counter = @Counter + 1	
		FETCH NEXT FROM TheCursor INTO @TempString	
		IF (@@FETCH_STATUS=0)
		SELECT @Comments = (@Comments + N', ' + @TempString ) 
	END
	CLOSE TheCursor
	DEALLOCATE TheCursor 
	
	INSERT INTO MoviesComments_ForView (Movie, Comments)
	SELECT DISTINCT M.Name, @Comments Comments
	FROM Movie M
	JOIN Feedback F
		ON M.MovieId = F.MovieId	
	WHERE M.Name = @CurrentMovie

	SELECT @MovieIterator = @MovieIterator +1
END 

IF OBJECT_ID('MoviesComments_vw', 'V') IS NOT NULL
DROP VIEW MoviesComments_vw;
GO
CREATE VIEW MoviesComments_vw
AS 
	SELECT * 
	FROM MoviesComments_ForView 
GO

SELECT * FROM MoviesComments_vw ;

-- 10) Створити прендставлення: актори, які не знімалися в фільмах.

IF OBJECT_ID('NotUsedActors_vw', 'V') IS NOT NULL
DROP VIEW NotUsedActors_vw;
GO
CREATE VIEW NotUsedActors_vw
AS 
	SELECT A2.Name
	FROM Actor A2

	EXCEPT 

	SELECT A.Name
	FROM Actor A
	JOIN Cast C 
		ON A.ActorId = C.ActorId
GO

SELECT * FROM NotUsedActors_vw

-- 11) Створити прендставлення: актори та суми отриманих гонорарів

IF OBJECT_ID('ActorFees_vw', 'V') IS NOT NULL
DROP VIEW ActorFees_vw;
GO
CREATE VIEW ActorFees_vw
AS 
	SELECT A.Name, SUM(C.Fee) Fees
	FROM Actor A
	JOIN Cast C 
		ON A.ActorId = C.ActorId
	GROUP BY A.Name
GO

SELECT * FROM ActorFees_vw


-- 12) Створити прендставлення: Ім’я актора, та його гонорар по кожного фільму

IF OBJECT_ID('ActorFeesByMovie_vw', 'V') IS NOT NULL
DROP VIEW ActorFeesByMovie_vw;
GO
CREATE VIEW ActorFeesByMovie_vw
AS 
	SELECT A.Name Actor, C.Fee, M.Name Movie
	FROM Actor A
	JOIN Cast C
		ON A.ActorId = C.ActorId
	JOIN Movie M 
		ON C.MovieId = M.MovieId
GO

SELECT * FROM ActorFeesByMovie_vw

