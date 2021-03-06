\name{hmd.mx}
\alias{hmd}
\alias{hmd.mx}
\alias{hmd.e0}
\title{Read demographic data from the Human Mortality Database}
\usage{hmd.mx(country, username, password, label = country)
hmd.e0(country, username, password)
}

\arguments{
\item{country}{Directory abbreviation from the HMD. For instance, Australia = "AUS". See below for other countries.}
\item{username}{HMD username}
\item{password}{HMD password}
\item{label}{Character string giving name of country from which the data are taken.}
}

\description{\code{hmd.mx} reads "Mx" (1x1) data from the Human Mortality Database (\url{http://www.mortality.org}) and constructs a demogdata object
suitable for plotting using \code{\link{plot.demogdata}} and fitting an LC or BMS model using \code{\link{lca}} or an 
FDA model using \code{\link{fdm}}.
\code{hmd.e0} reads life expectancy at birth from the Human Mortality Database and returns the result as a \code{ts} object.
}

\details{In order to read the data, users are required to create their account via the HMD website (\url{http://www.mortality.org}), 
and obtain a valid username and password.

The country codes (as at 31 July 2012) are as follows.
\tabular{ll}{
Australia \tab AUS\cr
Austria \tab AUT\cr
Belarus \tab BLR\cr
Belgium \tab BEL\cr
Bulgaria \tab BGR\cr
Canada \tab CAN\cr
Chile \tab CHL\cr
Czech Republic \tab CZE\cr
Denmark \tab DNK\cr
Estonia \tab EST\cr
Finland \tab FIN\cr
France\cr
  -- France total population \tab FRATNP\cr
  -- France civilian population \tab FRACNP\cr
Germany\cr	
  -- Germany total population \tab DEUTNP\cr
  -- West Germany \tab DEUTFRG\cr
  -- East Germany \tab DEUTGDR\cr
Hungary \tab HUN\cr
Iceland \tab ISL\cr
Ireland \tab IRL\cr
Israel \tab ISR\cr
Italy \tab ITA\cr
Japan \tab JPN\cr
Latvia \tab LVA\cr
Lithuania \tab LTU\cr
Luxembourg \tab LUX\cr
Netherlands \tab NLD\cr
New Zealand	\cr
  -- NZ total population \tab NZL_NP\cr
  -- NZ Maori \tab NZL_MA\cr
  -- NZ non-Maori \tab NZL_NM\cr
Norway \tab NOR\cr
Poland \tab POL\cr
Portugal \tab PRT\cr
Russia \tab RUS\cr
Slovakia \tab SVK\cr
Slovenia \tab SVN\cr
Spain \tab ESP\cr
Sweden \tab SWE\cr
Switzerland \tab CHE\cr
Taiwan \tab TWN\cr
United Kingdom\cr	
  -- UK Total Population \tab GBR_NP\cr
  -- England & Wales Total Population \tab GBRTENW\cr
  -- England & Wales Civilian Population \tab GBRCENW\cr
  -- Scotland \tab GBR_SCO\cr
  -- Northern Ireland \tab GBR_NIR\cr
U.S.A. \tab USA\cr
Ukraine \tab UKR\cr
}
Later additions to the HMD are listed at \url{http://www.mortality.org/cgi-bin/hmd/hmd_download.php}.
}

\value{\code{hmd.mx} returns an object of class \code{demogdata} with the following components:
\item{year}{Vector of years}
\item{age}{Vector of ages}
\item{rate}{A list containing one or more rate matrices with one age group per row and one column per year.}
\item{pop}{A list of the same form as \code{rate} but containing population numbers instead of demographic rates.}
\item{type}{Type of object: \dQuote{mortality}, \dQuote{fertility} or \dQuote{migration}.}
\item{label}{label}
\code{hmd.e0} returns an object of class \code{ts} with columns \code{male}, \code{female} and \code{total}.
}

\seealso{\code{\link{demogdata}},\code{\link{read.demogdata}},\code{\link{life.expectancy}}}

\examples{
\dontrun{
norway <- hmd.mx("NOR", username, password, "Norway")
summary(norway)}
}

\author{Rob J Hyndman}
\keyword{manip}
