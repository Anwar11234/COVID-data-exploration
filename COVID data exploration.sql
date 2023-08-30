-- Looking at total cases vs total deaths
select location , date , total_cases , total_deaths , (total_deaths / total_cases) * 100 as death_percentage 
from CovidDeaths$ 
where location = 'Egypt'
order by 1,2

-- Looking at total cases vs population
select location , date ,population ,total_cases , (total_cases / population) * 100 as covid_percentage 
from CovidDeaths$ 
where location = 'Egypt'
order by 1,2

-- Looking at countries with highest infection rate compared to population
select location ,population , MAX(total_cases) highest_infection_count , MAX(total_cases / population) * 100 as percent_population_infected
from CovidDeaths$ 
group by location , population
order by percent_population_infected desc

-- Looking at countries with highest death count for each country
select location , MAX(cast(total_deaths as int)) as total_death_count 
from CovidDeaths$ 
where continent is not null
group by location
order by total_death_count desc

-- Looking at each continent's highest death count
select location , MAX(cast(total_deaths as int)) as total_death_count 
from CovidDeaths$ 
where continent is  null
group by location
order by total_death_count desc

-- Looking at the new cases, new deaths, and death percentage for everyday across the world
select date , SUM(new_cases) as total_cases , SUM(cast(new_deaths as int)) as total_deaths,
(SUM(cast(new_deaths as int)) / SUM(new_cases)) * 100 as death_percentage
from CovidDeaths$ 
where continent is not null 
group by date 
order by 1,2

-- total cases and total deaths  across the world
select SUM(new_cases) as total_cases , SUM(cast(new_deaths as int)) as total_deaths,
(SUM(cast(new_deaths as int)) / SUM(new_cases)) * 100 as death_percentage
from CovidDeaths$ 
where continent is not null 
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
select cd.continent ,  cd.location , cd.date ,  cd.population , cv.new_vaccinations, 
SUM(CONVERT(int , cv.new_vaccinations)) OVER (partition by cd.location order by cd.location , cd.date) as 
cumulative_new_vaccinations
from CovidDeaths$ cd
JOIN CovidVaccinations$ cv 
ON cd.date = cv.date and cd.location = cv.location
where cd.continent is not null
order by 2 , 3

-- Using CTE to perform Calculation on Partition By in previous query

with PopulationVsVaccination (continent , location , date , population , new_vaccinations , cumulative_new_vaccinations)
as 
(
select cd.continent ,  cd.location , cd.date ,  cd.population , cv.new_vaccinations, 
SUM(CONVERT(int , cv.new_vaccinations)) OVER (partition by cd.location order by cd.location , cd.date) as 
cumulative_new_vaccinations
from CovidDeaths$ cd
JOIN CovidVaccinations$ cv 
ON cd.date = cv.date and cd.location = cv.location
where cd.continent is not null
)
select * , (cumulative_new_vaccinations / population) * 100
from PopulationVsVaccination

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated(
Continent nvarchar(255) , 
Location nvarchar(255) , 
Date datetime , 
Population numeric , 
New_vaccinations numeric,
CumulativeNewVaccinations numeric
)
INSERT INTO #PercentPopulationVaccinated
select cd.continent ,  cd.location , cd.date ,  cd.population , cv.new_vaccinations, 
SUM(CONVERT(int , cv.new_vaccinations)) OVER (partition by cd.location order by cd.location , cd.date) as 
cumulative_new_vaccinations
from CovidDeaths$ cd
JOIN CovidVaccinations$ cv 
ON cd.date = cv.date and cd.location = cv.location
where cd.continent is not null

select * , (CumulativeNewVaccinations / Population) * 100
from #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated
AS 
select cd.continent ,  cd.location , cd.date ,  cd.population , cv.new_vaccinations, 
SUM(CONVERT(int , cv.new_vaccinations)) OVER (partition by cd.location order by cd.location , cd.date) as 
cumulative_new_vaccinations
from CovidDeaths$ cd
JOIN CovidVaccinations$ cv 
ON cd.date = cv.date and cd.location = cv.location
where cd.continent is not null