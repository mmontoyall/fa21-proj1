-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
	SELECT MAX(era)
	FROM pitching
;
-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) as avgH, COUNT(*)
  FROM people
  GROUP BY birthyear
  HAVING avgH > 70
  ORDER BY birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, p.playerid, yearid
  FROM People as p , HallofFame as h
  WHERE p.playerid = h.playerid and h.inducted = 'Y'
  ORDER BY yearid DESC, p.playerid ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT namefirst, namelast, p.playerid, s.schoolid, yearid
  FROM People as p , HallofFame as h, Schools as s, CollegePlaying as cp
  WHERE p.playerid = h.playerid and h.inducted = 'Y' 
  and p.playerid = cp.playerid and cp.schoolID = s.schoolID and s.schoolState = 'CA'
  ORDER BY yearid DESC, p.playerid ASC
  
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, cp.schoolid
  FROM People as p LEFT OUTER JOIN CollegePlaying as cp ON p.playerid = cp.playerid, 
  HallofFame as h
  WHERE p.playerid = h.playerid and h.inducted = 'Y' 
  ORDER BY p.playerid DESC, cp.schoolID ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT b.playerid, namefirst, namelast, b.yearid,
  --Slugging Percentage:
  ( ((H - H2B - H3B - HR) + 2*H2B + 3*H3B + 4*HR + 0.0) / AB ) as slg
  FROM batting as b LEFT OUTER JOIN people as p on b.playerid = p.playerid
  WHERE AB > 50
  ORDER BY slg DESC, b.yearid ASC, p.playerid ASC
  limit 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT b.playerid, namefirst, namelast,
  --Slugging Percentage, we aggregate because its lifetime!:
  ( ((SUM(H) - SUM(H2B) - SUM(H3B) - SUM(HR)) + 2*SUM(H2B) + 3*SUM(H3B) + 4*SUM(HR) + 0.0) / SUM(AB) ) as lslg
  FROM batting as b LEFT OUTER JOIN people as p on b.playerid = p.playerid
  GROUP BY b.playerid
  HAVING SUM(AB) > 50
  ORDER BY lslg DESC, p.playerid ASC
  limit 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT namefirst, namelast,
  --Slugging Percentage, we aggregate because its lifetime!:
  ( ((SUM(H) - SUM(H2B) - SUM(H3B) - SUM(HR)) + 2*SUM(H2B) + 3*SUM(H3B) + 4*SUM(HR) + 0.0) / SUM(AB) ) as lslg
  FROM batting as b LEFT OUTER JOIN people as p on b.playerid = p.playerid
  GROUP BY b.playerid
  HAVING SUM(AB) > 50 
  --SUBQUERY looking for Maywis01 lslg
  AND lslg > (SELECT
				--Slugging Percentage, we aggregate because its lifetime!:
				( ((SUM(H) - SUM(H2B) - SUM(H3B) - SUM(HR)) + 2*SUM(H2B) + 3*SUM(H3B) + 4*SUM(HR) + 0.0) / SUM(AB) ) as lslg
				FROM batting as b LEFT OUTER JOIN people as p on b.playerid = p.playerid
				GROUP BY b.playerid
				HAVING SUM(AB) > 50 AND b.playerid LIKE 'mayswi01'
				ORDER BY lslg DESC, p.playerid ASC)			
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, min(salary), max(salary), avg(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH temp1 as (
	SELECT CAST( (salary - q4i.min)/( ((q4i.max+0.001) - q4i.min )/ 10) AS INT) as binid ,COUNT(*) as ct 
	FROM salaries INNER JOIN q4i ON salaries.yearid = q4i.yearid
	where salaries.yearid = 2016
	GROUP BY binid
	),
    lowInterval as (
	SELECT DISTINCT binid , q4i.min + binids.binid * ((q4i.max - q4i.min )/ 10) as low
	FROM binids, q4i
	where q4i.yearid = 2016
	Group BY binid
	),
    highInterval as (
	SELECT DISTINCT binids.binid, low , CASE
		WHEN low + ((q4i.max - q4i.min )/ 10) < q4i.max THEN CAST((low + ((q4i.max - q4i.min )/ 10)) AS VARCHAR(10))
		ELSE 'at least 33000000.0'
		END AS high
	FROM binids left join lowInterval on binids.binid = lowInterval.binid, q4i
	where q4i.yearid = 2016
	Group BY binids.binid
	)	
	
	select  highInterval.binid , low, high, ct
	from highInterval left join temp1 on  highInterval.binid = temp1.binid
  ;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  WITH shift1 as (
	SELECT yearid + 1 as yearid, min, max , avg
	FROM q4i
	)
  SELECT a.yearid, a.min - b.min , a.max - b.max, a.avg - b.avg
  FROM q4i as a INNER JOIN shift1 as b on a.yearid = b.yearid
  ORDER BY a.yearid ASC
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  WITH zero as (
	SELECT salaries.playerid as playerID, namefirst,namelast,salary,yearid 
	FROM salaries INNER JOIN people on salaries.playerID = people.playerID
	where salaries.yearid = 2000 and salary >= (SELECT max(salary)
												FROM salaries
												WHERE yearid = 2000
												GROUP BY yearid
												ORDER BY yearid ASC)
	),
	one as (
	SELECT salaries.playerid as playerID, namefirst,namelast,salary,yearid 
	FROM salaries INNER JOIN people on salaries.playerID = people.playerID
	where salaries.yearid = 2001 and salary >= (SELECT max(salary)
												FROM salaries
												WHERE yearid = 2001
												GROUP BY yearid
												ORDER BY yearid ASC)
	)
  SELECT * 
  FROM zero
  UNION
  SELECT *
  FROM one
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT allstarfull.teamID, max(salary)-min(salary) as diffAvg
  FROM allstarfull INNER JOIN salaries on allstarfull.playerID = salaries.playerID
  WHERE salaries.yearid = 2016 and allstarfull.yearid = 2016
  GROUP BY allstarfull.teamID
;

