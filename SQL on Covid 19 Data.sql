-- Covid 19 Data Exploration

-- Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

---

SELECT *
FROM [Portfolio Project].dbo.CovidDeaths$


SELECT location, date, total_cases,new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths$
ORDER BY 1, 2


--Total Cases vs Total Deaths and the likelyhood of death if one contrated covid in anyone of the listed months
SELECT location,date, SUM(COALESCE(total_cases, 0)) AS Total_Cases, SUM(COALESCE(total_deaths, 0)) AS Total_Deaths, SUM(COALESCE(total_deaths, 0))*100/SUM(total_cases) AS Ratio_of_deaths_from_total_cases
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL AND location LIKE '%South Africa%'
GROUP BY location, date
ORDER BY location ASC

--In South Africa what was the percentage of infection in each day per the entire population
-- Likelyhood of being infected in South Africa
SELECT location,date, population, COALESCE (total_cases, 0)*100/population AS infection_per_person, AVG(COALESCE (total_cases,0)) AS average_cases_per_day
FROM [Portfolio Project]..CovidDeaths$
WHERE location LIKE '%South Africa%' AND continent IS NOT NULL
GROUP BY location, date, population, total_cases
ORDER BY location ASC


--Looking at Total cases vs Population
--Shows what percentage of population got infected
SELECT location, population, MAX(total_cases) AS Highest_infection_Count, MAX((total_cases/population)*100) AS Max_Population_Per_Person
FROM [Portfolio Project]..CovidDeaths$
WHERE  continent IS NOT NULL
GROUP BY location, population
ORDER BY Highest_infection_Count DESC

--Showing countries with highest death count per population
SELECT location, population, SUM(COALESCE( total_deaths, 0)) AS Total_Number_of_Deaths, MAX(COALESCE(total_deaths,0)) AS Highest_Death_Count
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Total_Number_of_Deaths DESC


-- FOR OTHER POPULATIONAS


-- Select Data that we are going to be starting with
 SELECT location,
		date,
		population,
		new_cases,
		total_deaths
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY location;
---

-- Total Cases vs Total Deaths
SELECT location,
		date,
		population,
		SUM(COALESCE (new_cases, 0)) AS total_new_cases_per_day,
		SUM(COALESCE (total_deaths, 0)) AS total_deaths_per_day
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, date, population
ORDER BY location;
---
-- Shows likelihood of dying if you contract covid in your country
SELECT location,
		population,
		(SUM(COALESCE (total_deaths, 0))/population)*100 AS Death_Percentage_Per_capita
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Death_Percentage_Per_capita DESC;
---

-- Total Cases vs Population
SELECT location,
		population,
		SUM(COALESCE (total_cases, 0)) AS Total_cases
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Total_cases DESC;
-- Shows what percentage of population infected with Covid

SELECT location,
		population,
		(SUM(COALESCE (total_cases, 0))/population)*100 AS Total_infections_per_capita
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Total_infections_per_capita DESC;

-- Countries with Highest Infection Rate compared to Population

SELECT location,
		population,
		SUM(COALESCE (total_cases, 0))/population AS Total_cases
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Total_cases DESC;


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population
SELECT continent,
		SUM(COALESCE (total_deaths, 0)) AS Total_deaths_per_capita
FROM [Portfolio Project]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_deaths_per_capita DESC;

-- Total Population vs Vaccinations
SELECT cd.continent,
		cd.location,
		cd.date,
		cd.population,
		cv.total_vaccinations,
		SUM(COALESCE(cv.total_vaccinations, 0)) OVER (PARTITION BY cd.location ORDER BY cv.total_vaccinations, cd.date) AS TYH
FROM [Portfolio Project]..CovidDeaths$ AS cd
INNER JOIN [Portfolio Project]..CovidVaccinations$ AS cv
ON cd.location =cv.location
AND cd.date =cv.date
WHERE cd.continent IS NOT NULL 
ORDER BY 2,3


-- Shows Percentage of Population that has received at least one Covid Vaccine
SELECT 
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.total_vaccinations,
    SUM(CONVERT(bigint, cv.total_vaccinations))OVER (PARTITION BY cd.location ORDER BY cd.date)*100/cd.population  AS Percentage_of_people_vaccinated
FROM 
    [Portfolio Project]..CovidDeaths$ AS cd
INNER JOIN 
    [Portfolio Project]..CovidVaccinations$ AS cv
ON 
    cd.location = cv.location
AND 
    cd.date = cv.date
WHERE 
    cd.continent IS NOT NULL AND cv.total_vaccinations IS NOT NULL
ORDER BY 
    cd.location, cd.date;

-- Using CTE to perform Calculation on Partition By in previous query
WITH populationvsvaccine (continent, location, date, population, total_vaccinations, people_vaccinated)
AS
( 
    SELECT 
        cd.continent,
        cd.location,
        cd.date,
        cd.population,
        cv.total_vaccinations,
        SUM(CONVERT(bigint, cv.total_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS people_vaccinated
    FROM 
        [Portfolio Project]..CovidDeaths$ AS cd
    INNER JOIN 
        [Portfolio Project]..CovidVaccinations$ AS cv
    ON 
        cd.location = cv.location
    AND 
        cd.date = cv.date
    WHERE 
        cd.continent IS NOT NULL 
    AND 
        cv.total_vaccinations IS NOT NULL
)
SELECT *,
       (people_vaccinated * 1.0 / population) AS vaccination_rate
FROM populationvsvaccine
ORDER BY location, date;
-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
people_vaccinated numeric,
total_vaccinations numeric
)

Insert into #PercentPopulationVaccinated
 SELECT 
        cd.continent,
        cd.location,
        cd.date,
        cd.population,
        cv.total_vaccinations,
        SUM(CONVERT(bigint, cv.total_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS people_vaccinated
    FROM 
        [Portfolio Project]..CovidDeaths$ AS cd
    INNER JOIN 
        [Portfolio Project]..CovidVaccinations$ AS cv
    ON 
        cd.location = cv.location
    AND 
        cd.date = cv.date
    WHERE 
        cd.continent IS NOT NULL 
    AND 
        cv.total_vaccinations IS NOT NULL
	ORDER BY 2,3

Select *, (people_vaccinated/Population)*100 AS vaccination_rate
From #PercentPopulationVaccinated;



