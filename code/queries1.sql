-- check import worked correctly
select * from COVID_deaths..covid_deaths
where continent is not null
order by 3,4

select * from COVID_deaths..covid_vaccinations
where continent is not null
order by 3,4


-- investigate covid deaths data -- 
select location, date, total_cases, new_cases, total_deaths, population
from COVID_deaths..covid_deaths
where continent is not null
order by 1,2

-- total cases vs total deaths
Select location, date, total_cases,total_deaths, (CAST(total_deaths as float) / NULLIF(CAST(total_cases AS float), 0)) * 100 AS death_percentage
from COVID_deaths..covid_deaths
--where location like '%states%' 
where continent is not null
order by 1,2


-- total cases vs population
select location, date, total_cases, population, (CAST(total_cases as float)/population)*100 AS percent_pop_infected
from COVID_deaths..covid_deaths
--where location like '%states%'
where continent is not null
order by 1,2

-- countries with highest infection rates
select location, MAX(CAST(total_cases as float)) as highest_infection_count, MAX((CAST(total_cases as float)/population))*100 AS percent_pop_infected
from COVID_deaths..covid_deaths
--where location like '%states%'
where continent is not null
group by location, population
order by percent_pop_infected desc

-- countries with highest death counts
select location, MAX(CAST(total_deaths as float)) as total_death_count --, MAX((CAST(total_cases as float)/population))*100 AS percent_pop_infected
from COVID_deaths..covid_deaths
--where location like '%states%'
where continent is not null
group by location
order by total_death_count desc

-- total deaths broken down by continent
select location, MAX(CAST(total_deaths as float)) as total_death_count
from COVID_deaths..covid_deaths
--where location like '%states%'
where continent is null   --filters for those locations that ARE continents (or similar)
group by location
order by total_death_count desc

-- global numbers
select date, SUM(new_cases) as daily_new_cases, SUM(new_deaths) as daily_new_deaths
from COVID_deaths..covid_deaths
where continent is not null
group by date
order by 1,2

select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
SUM(new_deaths)/SUM(new_cases) as death_percentage
from COVID_deaths..covid_deaths
where continent is not null




-- join with vaccination data -- 
select * 
from COVID_deaths..covid_deaths dea
join COVID_deaths..covid_vaccinations vac
on dea.location = vac.location 
and dea.date = vac.date

-- total vaccinations 
select dea.continent, dea.location, dea.date, dea.population, new_vaccinations,
SUM(cast(new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, 
 dea.date) as rolling_ppl_vaccinated
from COVID_deaths..covid_deaths dea
join COVID_deaths..covid_vaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- total population vs vaccinations (problematic: guessing it's counting multiple vaccinations per person?)
with PopvsVac (Continent, Location, Date, Population, New_vaccinations, Rolling_ppl_vaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, new_vaccinations,
SUM(cast(new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, 
 dea.date) as rolling_ppl_vaccinated
from COVID_deaths..covid_deaths dea
join COVID_deaths..covid_vaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (rolling_ppl_vaccinated/population)*100
from PopvsVac


-- total population vs vaccinations, with a temp table
DROP Table if exists #percent_pop_vaccinated
create table #percent_pop_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_ppl_vaccinated numeric
)
insert into #percent_pop_vaccinated
select dea.continent, dea.location, dea.date, dea.population, new_vaccinations,
SUM(cast(new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, 
 dea.date) as rolling_ppl_vaccinated
from COVID_deaths..covid_deaths dea
join COVID_deaths..covid_vaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *, (rolling_ppl_vaccinated/population)
from #percent_pop_vaccinated


-- create view to store data for viz

create view percent_pop_vaccinated as
select dea.continent, dea.location, dea.date, dea.population, new_vaccinations,
SUM(cast(new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, 
 dea.date) as rolling_ppl_vaccinated
from COVID_deaths..covid_deaths dea
join COVID_deaths..covid_vaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null

select * 
from percent_pop_vaccinated