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
  SELECT namefirst,namelast,birthyear
  FROM people p
  WHERE p.weight>300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
   SELECT namefirst,namelast,birthyear
   FROM people p
   WHERE p.namefirst LIKE '% %'
   ORDER BY p.namefirst ASC,p.namelast ASC
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear,AVG(height),COUNT(*)
  FROM people p
  GROUP BY p.birthyear
  ORDER BY birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear,AVG(height),COUNT(*)
  FROM people p
  GROUP BY p.birthyear
  HAVING AVG(height)>70 
  ORDER BY birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerid, h.yearid
  FROM people p
  JOIN halloffame h ON p.playerid=h.playerid
  WHERE h.inducted = 'Y'
  ORDER BY h.yearid DESC, p.playerid ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS  
  SELECT p.namefirst, p.namelast, p.playerid, cp.schoolid,h.yearid
  FROM people p
  JOIN halloffame h ON p.playerid = h.playerid 
  JOIN collegeplaying cp ON p.playerid=cp.playerid
  JOIN schools s ON cp.schoolid=s.schoolid
  WHERE h.inducted = 'Y' and s.schoolstate='CA'
  ORDER BY h.yearid DESC,cp.schoolid ASC,p.playerid ASC
;



-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT p.playerid,p.namefirst,p.namelast,cp.schoolid
  FROM people p
  JOIN halloffame h ON p.playerid=h.playerid
  LEFT JOIN collegeplaying cp ON h.playerid =cp.playerid
  WHERE h.inducted = 'Y'
  ORDER BY h.playerid DESC,cp.schoolid ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid,p.namefirst,p.namelast,b.yearid,(CAST(b.H+b.H2B+2*b.H3B+3*b.HR AS REAL )/b.AB)  AS slg
  FROM people AS p JOIN batting AS b ON p.playerid = b.playerid
  WHERE b.AB > 50 
  ORDER BY slg DESC,b.yearid ASC,p.playerid ASC
   
   LIMIT 10;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  -- 使用 CTE (公用表表达式) 先计算每个球员的生涯总数据
WITH LifetimeStats AS (
    SELECT
        playerid,
        SUM(AB) AS lifetime_ab,
        SUM(H) AS lifetime_h,
        SUM(H2B) AS lifetime_h2b,
        SUM(H3B) AS lifetime_h3b,
        SUM(HR) AS lifetime_hr
    FROM
        Batting
    GROUP BY
        playerid
    HAVING
        SUM(AB) > 50 -- 筛选生涯总打数超过50的球员
)
-- 主查询：计算 LSLG，连接球员信息，并选出前10名
SELECT
    p.playerid,
    p.namefirst,
    p.namelast,
    -- 计算 LSLG，并使用 CAST 确保结果为浮点数
    CAST(
        ls.lifetime_h + ls.lifetime_h2b + 2 * ls.lifetime_h3b + 3 * ls.lifetime_hr AS REAL
    ) / ls.lifetime_ab AS lslg
FROM
    People AS p
JOIN
    LifetimeStats AS ls ON p.playerid = ls.playerid
ORDER BY
    lslg DESC,      -- 按 LSLG 降序排序
    p.playerid ASC  -- 如果 LSLG 相同，则按 playerid 升序排序
LIMIT 10;           -- 限制输出为前10条记录
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid,MIN(salary),MAX(salary),AVG(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
-- CTE to calculate statistics for 2016 salaries
WITH YearStats AS (
  SELECT
    MIN(salary) AS min_salary,
    -- Using CAST to ensure floating point division, which is safer in SQLite
    (CAST(MAX(salary) AS REAL) - MIN(salary)) / 10.0 AS bin_width
  FROM salaries
  WHERE yearid = 2016
),
-- CTE to generate numbers 0-9 as a replacement for generate_series.
-- This works in virtually all SQL databases, including SQLite.
Bins AS (
  SELECT 0 AS binid UNION ALL
  SELECT 1 UNION ALL
  SELECT 2 UNION ALL
  SELECT 3 UNION ALL
  SELECT 4 UNION ALL
  SELECT 5 UNION ALL
  SELECT 6 UNION ALL
  SELECT 7 UNION ALL
  SELECT 8 UNION ALL
  SELECT 9
),
-- CTE to define the boundaries (low and high) for each bin
BinBoundaries AS (
  SELECT
    b.binid,
    ys.min_salary + (b.binid * ys.bin_width) AS low,
    ys.min_salary + ((b.binid + 1) * ys.bin_width) AS high
  FROM
    Bins b, YearStats ys -- Implicit CROSS JOIN
)
-- Final query to count salaries in each bin
SELECT
  bb.binid,
  bb.low,
  bb.high,
  COUNT(s.salary) AS count
FROM
  BinBoundaries bb
LEFT JOIN
  salaries s ON s.yearid = 2016 AND (
    -- Bins 0-8 have a left-inclusive, right-exclusive range: [low, high)
    (bb.binid < 9 AND s.salary >= bb.low AND s.salary < bb.high)
    OR
    -- The last bin (bin 9) has a fully inclusive range: [low, high]
    (bb.binid = 9 AND s.salary >= bb.low AND s.salary <= bb.high)
  )
GROUP BY
  bb.binid, bb.low, bb.high
ORDER BY
  bb.binid ASC;
-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
-- 第一步：和之前一样，先计算每年的统计数据
WITH YearlyStats AS (
  SELECT
    yearid,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary,
    AVG(salary) AS avg_salary
  FROM
    salaries
  GROUP BY
    yearid
)
-- 第二步：使用自连接将每一年与其上一年配对
SELECT
  current_year.yearid,
  -- 计算当前年份与上一年的差值
  current_year.min_salary - previous_year.min_salary AS mindiff,
  current_year.max_salary - previous_year.max_salary AS maxdiff,
  current_year.avg_salary - previous_year.avg_salary AS avgdiff
FROM
  YearlyStats AS current_year
-- 关键：将 YearlyStats 表与它自己连接
JOIN
  YearlyStats AS previous_year ON current_year.yearid = previous_year.yearid + 1
ORDER BY
  current_year.yearid ASC-- replace this line
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT p.playerid,p.namefirst,p.namelast,MAX(s.salary),s.yearid
  FROM people p
  JOIN salaries AS s ON p.playerid=s.playerid
  WHERE s.yearid =2000 OR s.yearid = 2001
  GROUP BY s.yearid-- replace this line
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT a.teamid AS team,MAX(s.salary)-MIN(s.salary) AS diffAvg
  FROM allstarfull AS a
  JOIN salaries AS s ON a.playerid=s.playerid AND a.yearid = s.yearid
  WHERE  s.yearid=2016
  GROUP BY a.teamid-- replace this line
;

