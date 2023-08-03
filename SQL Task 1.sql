SELECT pName FROM tProducts;

SELECT pName FROM  tProducts WHERE pName LIKE '%2%';

SELECT pName, pPrice FROM  tProducts WHERE pPrice < 10;

SELECT pBarCode, pPrice FROM tProducts WHERE pComment IS NULL;

SELECT cName FROM tClients;

SELECT cName FROM tClients WHERE cName LIKE '%CL';

SELECT cName, cAddress FROM tClients WHERE cAddress IS NOT NULL;

SELECT cInstance, cName FROM tClients WHERE cAmount <0;

SELECT DISTINCT pPrice Φ³νθ FROM tProducts;

SELECT pName, pPrice FROM tProducts WHERE pPrice < 300;

SELECT cName, cAmount FROM tClients WHERE cAmount NOT BETWEEN 100 AND 600;

SELECT dInstance, dClient, dAmount, dComment FROM tDocuments where dComment IS NOT NULL;

SELECT dClient FROM tDocuments WHERE dDate = '04/04/2016';
