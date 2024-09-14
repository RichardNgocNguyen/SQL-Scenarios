-- Usage of SELECT, FROM, WHERE & ORDER BY
------------------------------------------------------------------------------------------------------------------
--8
SELECT contactfirstname, contactlastname, creditlimit
FROM customers
WHERE (creditlimit > 50000)
ORDER BY contactlastname, contactfirstname;

--9
SELECT customername
FROM customers
WHERE (creditlimit = 0)
ORDER BY customername;

--10
SELECT city, phone, addressline1, country, postalcode, territory
FROM offices
WHERE NOT country = 'USA';

--11
SELECT orderdate, requireddate, shippeddate, status, comments
FROM orders
WHERE orderdate >= '2014-6-16' and orderdate <= '2014-7-7';

--12
SELECT productcode, productname, productvendor, quantityinstock
FROM products
WHERE (quantityinstock < 1000);

--13
SELECT ordernumber, shippeddate, requireddate
FROM orders
WHERE shippeddate > requireddate;

--14
SELECT customername
FROM customers
WHERE customername LIKE '%Mini%';

--15
SELECT productname
FROM products
WHERE productvendor = 'Highway 66 Mini Classics';

--16
SELECT productname, productvendor
FROM products
WHERE NOT productvendor = 'Highway 66 Mini Classics'
ORDER BY productname;

--17
SELECT lastname, firstname
FROM employees
WHERE reportsto IS NULL;


-- Inner Joins/ Outer Joins
------------------------------------------------------------------------------------------------------------------
--18
SELECT ordernumber, orderdate, status, quantityordered, priceeach, productname
FROM orderdetails
INNER JOIN products USING (productcode)
INNER JOIN orders USING(ordernumber)
WHERE ordernumber IN (10270,10272,10279);

--19
SELECT DISTINCT productline, SUBSTR(textdescription, 1,50), productvendor
FROM productlines
INNER JOIN products USING(productline)
ORDER BY productline, productvendor;

--20
SELECT customername, state
FROM customers
INNER JOIN offices USING(state)
ORDER BY customername;

--21
SELECT customername
FROM customers c
INNER JOIN employees e ON e.employeenumber = c.salesrepemployeenumber
INNER JOIN offices o ON o.officecode = e.officecode
WHERE o.state = c.state;

--22
SELECT customername, orderdate, quantityordered, productline, productname
FROM orderdetails
INNER JOIN orders USING(ordernumber)
INNER JOIN products USING(productcode)
INNER JOIN customers USING(customernumber)
WHERE (customername LIKE '%Decorations%') and
      (MOD(EXTRACT(MONTH FROM shippeddate), 2) = 1) and
      (EXTRACT(YEAR FROM shippeddate) = 2015)
ORDER BY customername, orderdate;

--23
SELECT productname, ordernumber
FROM products p
LEFT OUTER JOIN orderdetails o ON p.productcode = o.productcode
WHERE ordernumber is NULL;

--24
SELECT customername, firstname, lastname
FROM customers c
LEFT OUTER JOIN employees e ON e.employeenumber = c.salesrepemployeenumber;


--Set Operations
----------------------------------------------------------------------------------------------------
--37
SELECT customerName From customers
EXCEPT
SELECT DISTINCT customerName
From customers INNER JOIN orders USING(customernumber)
WHERE orderdate >= '2015-01-01' AND orderdate <= '2015-12-31'
ORDER BY customername;
--38
SELECT contactFirstName AS "First Name",contactLastName AS "Last Name", customerName AS "Company Name"
FROM customers
UNION
SELECT firstName AS first_name, lastName AS last_name, 'Employee' AS "Company Name"
FROM employees;

--39
SELECT lastName, firstName, employeeNumber
FROM employees
EXCEPT
SELECT DISTINCT lastName, firstName, employeeNumber
FROM employees e INNER JOIN customers c
ON e.employeeNumber = c.salesrepemployeenumber
ORDER BY lastname, firstname;

--40
SELECT country, state, 'Customer' AS "Category"
FROM customers
WHERE state NOT IN (SELECT state FROM offices WHERE state IS NOT NULL)
UNION
SELECT country, state, 'Office' AS "Category"
FROM offices
WHERE state NOT IN (SELECT state FROM customers WHERE state IS NOT NULL)
UNION
SELECT country, state, 'Both' AS "Category"
FROM customers
WHERE (state IN (SELECT state FROM offices WHERE state IS NOT NULL) AND
state IN (SELECT state FROM customers WHERE state IS NOT NULL))
ORDER BY country, state;

--42
SELECT DISTINCT customername
FROM customers  INNER JOIN orders USING(customernumber)
                INNER JOIN orderdetails USING(ordernumber)
                INNER JOIN products USING(productcode)
WHERE productline = 'Trains'
UNION
SELECT DISTINCT customername
FROM customers  INNER JOIN orders USING(customernumber)
                INNER JOIN orderdetails USING(ordernumber)
                INNER JOIN products USING(productcode)
WHERE productline = 'Trucks and Buses'
ORDER BY customername;

--43
SELECT c1.customername, c1.state, c1.country
FROM (SELECT customernumber, customername, COALESCE(state, 'N/A') state, country
FROM customers) AS c1
WHERE NOT EXISTS
(SELECT 'X' FROM (SELECT customernumber, COALESCE(state, 'N/A') state, country FROM customers) AS c_other
WHERE c1.customernumber <> c_other.customernumber AND c1.state = c_other.state AND c1.country = c_other.country)
ORDER BY customername;


--Aggregate Functions
---------------------------------------------------------------------------------------------------
--25
SELECT customername as "Customer Name", SUM(amount) as "Total Spent"
FROM customers INNER JOIN payments USING(customernumber)
GROUP BY customername;

--26
SELECT MAX(amount) as "Largest Amount"
FROM payments;

--27
SELECT AVG(amount) as "Average Amount"
FROM payments;

--28
SELECT productline as "Product Line", COUNT(productname) as "Products"
FROM products
GROUP BY productline;

--29
SELECT status as "Status", COUNT(ordernumber) as "Orders"
FROM orders
GROUP BY status;

--30
SELECT city, phone, addressline1, state, country, postalcode, territory, COUNT(employeenumber) as "Employee"
FROM offices INNER JOIN employees USING(officecode)
GROUP BY city, phone, addressline1, state, country, postalcode, territory;

--31
SELECT productline as "Product Line", COUNT(productname) as "Products"
FROM products
GROUP BY productline
HAVING COUNT(productname) > 3;

--32
SELECT ordernumber, SUM(quantityordered * priceeach) as "Order Total"
FROM orderdetails
GROUP BY ordernumber
HAVING SUM(quantityordered * priceeach) > 60000;


-- Sub-queries
-----------------------------------------------------------------------------------------------------
--44
SELECT productname
FROM products
WHERE productcode = (SELECT productcode FROM orderdetails
                    GROUP BY productcode
                    ORDER BY SUM(quantityordered*priceeach) DESC LIMIT 1);

--45
SELECT productline, productvendor
FROM products
WHERE productline = (SELECT productline FROM products
GROUP BY productline
HAVING COUNT(productvendor) < 5);

--46
SELECT productname, productline
FROM products
WHERE productline =
(
    SELECT productline AS num_product
    FROM products
    GROUP BY productline
    HAVING COUNT(productname) =
    (
        SELECT MAX(counts.num_product) AS maximum
        FROM
        (
            SELECT COUNT(productname) AS num_product
            FROM products
            GROUP BY productline
        ) AS counts
    )
);

--47
SELECT contactfirstname, contactlastname
FROM customers
WHERE state = (SELECT DISTINCT state FROM customers
                WHERE city = 'San Francisco'
);

--48
SELECT customername, salesrepemployeenumber
FROM customers
WHERE customernumber =
      (SELECT customernumber
        FROM orders
        WHERE ordernumber = (
            SELECT ordernumber
            FROM orderdetails
            GROUP BY ordernumber
            HAVING SUM(priceeach*quantityordered) =
                (SELECT MAX(total.total_spent)
                FROM
                    (SELECT SUM(priceeach*quantityordered) AS total_spent
                    FROM orderdetails
                    GROUP BY ordernumber
                    ) AS total
                )
        )
);

--49
SELECT ordernumber, SUM(priceeach*quantityordered) AS total_spent
FROM customers
    INNER JOIN orders USING(customernumber)
    INNER JOIN orderdetails USING (ordernumber)
WHERE customernumber =
      (SELECT customernumber
       FROM orders
       WHERE ordernumber =
        (SELECT ordernumber
        FROM orderdetails
        GROUP BY ordernumber
        HAVING SUM(priceeach*quantityordered) =
            (SELECT MAX(total.order_total)
            FROM
            (
                SELECT SUM(priceeach*quantityordered) AS order_total
                FROM orderdetails
                GROUP BY ordernumber
            ) AS total
        )
    )
)
AND ordernumber =
    (SELECT ordernumber
    FROM orderdetails
    GROUP BY ordernumber
    HAVING SUM(priceeach*quantityordered) =
        (SELECT MAX(total.order_total)
        FROM
            (SELECT SUM(priceeach*quantityordered) AS order_total
            FROM orderdetails
            GROUP BY ordernumber
        ) AS total
    )
)
GROUP BY customername, ordernumber;

--50
SELECT customername ,ordernumber, SUM(priceeach*quantityordered) AS "total_cost"
FROM orderdetails INNER JOIN orders USING (ordernumber)
INNER JOIN customers USING (customernumber)
GROUP BY customername, ordernumber
HAVING SUM(priceeach*quantityordered) =
(
    SELECT MAX(total.total_spent)
    FROM
    (
        SELECT SUM(priceeach*quantityordered) AS "total_spent"
        FROM orderdetails
        GROUP BY ordernumber
    ) AS total
);

--52
SELECT customername
FROM customers  INNER JOIN orders USING (customernumber)
    INNER JOIN orderdetails  USING (ordernumber)
    INNER JOIN products AS p USING (productcode)
WHERE p.productname IN
     (SELECT productname FROM customers INNER JOIN orders USING (customernumber)
         INNER JOIN orderdetails USING(ordernumber)
         INNER JOIN products USING (productcode)
    WHERE customername = 'Dragon Souveniers, Ltd.' AND productname LIKE '%Ford%')
GROUP BY customername HAVING COUNT (p.productname) >= 1
                               ORDER BY customername DESC;