# Lifetable functions
# Produce lifetable from mortality rates

lifetable <- function(data, series=names(data$rate)[1], years=data$year, ages=data$age,
	max.age=min(100,max(data$age)), type=c("period","cohort"))
{
  if(!is.element("demogdata",class(data)))
    stop("data must be a demogdata object")
  if(data$type != "mortality")
    stop("data must be a mortality object")
  type <- match.arg(type)
  if(!is.el(series,names(data$rate)))
    stop(paste("Series",series,"not found"))
  if(is.na(sum(match(years,data$year))))
    stop("Years not present in data")
  sex <- series
  if(sex!="female" & sex!="male" & sex!="total")
  {
    if(is.element("model",names(data)))
      sex <- names(data$model)[4]
  }
  na <- length(data$age)
  if(na > 4)
  	agegroup <- data$age[na-1]-data$age[na-2]
  else
    stop("Insufficient age groups")

	if(type=="period")
	{
		max.age <- min(max.age,max(ages))
		data <- extract.ages(data,ages,combine.upper=FALSE)
		if(max.age < max(ages))
			data <- extract.ages(data,min(ages):max.age,combine.upper=TRUE)
		data <- extract.years(data,years=years)
		mx <- get.series(data$rate,series)
		n <- length(years)
		p <- nrow(mx)
		rownames(mx) <- ages <- data$age
		colnames(mx) <- years
		qx <- lx <- dx <- Lx <- Tx <- ex <- rx <- mx*NA
		rownames(rx) <- ages - 1
		rownames(rx)[ages==0] <- "B"
		for(i in 1:n)
		{
			ltable <- lt(mx[,i],min(ages),agegroup,sex)
			nn <- length(ltable$qx)
			qx[1:nn,i] <- ltable$qx
			lx[1:nn,i] <- ltable$lx
			dx[1:nn,i] <- ltable$dx
			Lx[1:nn,i] <- ltable$Lx
			Tx[1:nn,i] <- ltable$Tx
			ex[1:nn,i] <- ltable$ex
			rx[1:nn,i] <- ltable$rx
		}
	}
	else if(type=="cohort" & length(ages)>1) # multiple ages, single year.
	{
		data <- extract.ages(data,min(ages):max.age,combine.upper=TRUE)
		data <- extract.years(data,years=seq(min(years),max(data$year),by=1))
		n <- length(data$year)
		p <- length(data$age)
		cmx <- matrix(NA,p,p)
		rownames(cmx) <- data$age
		colnames(cmx) <- paste(min(years)," age ",data$age,sep="")
		qx <- dx <- Tx <- lx <- Lx <- ex <- cmx
		cohort <- match(ages,data$age)
		cohort <- cohort[!is.na(cohort)]
		if(length(cohort)==0)
			stop("No data available")
		if(min(data$age[cohort]+n-1) < max.age)
			warning("Insufficient data for other lifetables. Try reducing max.age")
		for(coh in cohort)
		{
			if(data$age[coh]+n-1 > max.age)
			{
				subdata <- extract.ages(data,data$age[coh]:max.age,combine.upper=TRUE)
				mx <- get.series(subdata$rate,series)
				p <- nrow(mx)
				for (j in 1:p)
					cmx[coh+j-1,coh] <- mx[j,j]
				ltable <- lt(cmx[coh+(1:p)-1,coh], data$age[coh], agegroup, sex=sex)
				p <- length(ltable$lx)
				lx[coh+(1:p)-1,coh] <- ltable$lx
				Lx[coh+(1:p)-1,coh] <- ltable$Lx
				ex[coh+(1:p)-1,coh] <- ltable$ex
				qx[coh+(1:p)-1,coh] <- ltable$qx
				dx[coh+(1:p)-1,coh] <- ltable$dx
				Tx[coh+(1:p)-1,coh] <- ltable$Tx
			}
		}
		mx <- cmx
		# Retain columns in required cohort
		mx <- mx[,cohort,drop=FALSE]
		lx <- lx[,cohort,drop=FALSE]
		Lx <- Lx[,cohort,drop=FALSE]
		ex <- ex[,cohort,drop=FALSE]
		qx <- qx[,cohort,drop=FALSE]
		dx <- dx[,cohort,drop=FALSE]
		Tx <- Tx[,cohort,drop=FALSE]
		rx <- NULL
	}
	else #single age, multiple years.
	{
		data <- extract.years(data,years=seq(min(years),max(data$year),by=1))
		data <- extract.ages(data,ages:max.age,combine.upper=TRUE)
		n <- length(data$year)
		p <- length(data$age)
		ny <- length(years)
		cmx <- matrix(NA,p,ny)
		rownames(cmx) <- data$age
		colnames(cmx) <- paste(years," age ",ages,sep="")
		qx <- dx <- Tx <- lx <- Lx <- ex <- cmx
		minage <- max.age
		for(i in 1:ny)
		{
			subdata <- extract.years(data,years=seq(years[i],max(data$year),by=1))
			upperage <- min(ages+length(subdata$year)-1)
			minage <- min(minage,upperage)
			if(upperage >= max.age)
			{
				mx <- get.series(subdata$rate,series)
				p <- nrow(mx)
				for (j in 1:p)
					cmx[j,i] <- mx[j,j]
				ltable <- lt(cmx[,i],ages, agegroup, sex=sex)
				p <- length(ltable$lx)
				lx[1:p,i] <- ltable$lx
				Lx[1:p,i] <- ltable$Lx
				ex[1:p,i] <- ltable$ex
				qx[1:p,i] <- ltable$qx
				dx[1:p,i] <- ltable$dx
				Tx[1:p,i] <- ltable$Tx
			}
		}
		mx <- cmx
		rx <- NULL
#		if(minage < max.age)
#        {
#			warning("Insufficient data for other life tables. Try reducing max.age")
#        }
	}

	return(structure(list(age=ages,year=years, mx=mx,qx=qx,lx=lx,dx=dx,Lx=Lx,Tx=Tx,ex=ex,rx=rx,
        series=series, type=type, label=data$label),class="lifetable"))
}

lt <- function (mx, startage = 0, agegroup = 5, sex)
{
    # Omit missing ages
    if (is.na(mx[1]))
        mx[1] <- 0
    firstmiss <- (1:length(mx))[is.na(mx)][1]
    if (!is.na(firstmiss))
        mx <- mx[1:(firstmiss - 1)]
    nn <- length(mx)
    if (nn < 1)
        stop("Not enough data to proceed")

    # Compute width of each age group
    if (agegroup == 1)
        nx <- c(rep(1, nn - 1), Inf)
    else if (agegroup == 5) # First age group 0, then 1-4, then 5-year groups.
        nx <- c(1, 4, rep(5, nn - 3), Inf)
    else stop("agegroup must be either 1 or 5")

    if (agegroup == 5 & startage > 0 & startage < 5)
        stop("0 < startage < 5 not supported for 5-year age groups")

    if (startage == 0) { # for single year data and the first age (0) in 5-year data
        if (sex == "female") {
            if (mx[1] < 0.107)
                a0 <- 0.053 + 2.8 * mx[1]
            else a0 <- 0.35
        }
        else if (sex == "male") {
            if (mx[1] < 0.107)
                a0 <- 0.045 + 2.684 * mx[1]
            else a0 <- 0.33
        }
        else { # if(sex == "total")
            if (mx[1] < 0.107)
                a0 <- 0.049 + 2.742 * mx[1]
            else a0 <- 0.34
        }
    }
    else if (startage > 0)
        a0 <- 0.5
    else stop("startage must be non-negative")
    if (agegroup == 1) {
        if (nn > 1)
            ax <- c(a0, rep(0.5, nn - 2), Inf)
        else ax <- Inf
    }
    else if (agegroup == 5 & startage == 0) {
        if (sex == "female") {
            if (mx[1] < 0.107)
                a1 <- 1.522 - 1.518 * mx[1]
            else a1 <- 1.361
        }
        else if (sex == "male") {
            if (mx[1] < 0.107)
                a1 <- 1.651 - 2.816 * mx[1]
            else a1 <- 1.352
        }
        else { # sex == "total"
            if (mx[1] < 0.107)
                a1 <- 1.5865 - 2.167 * mx[1]
            else a1 <- 1.3565
        }
        ax <- c(a0, a1, rep(2.6, nn - 3), Inf)
        ### ax=2.5 known to be too low esp at low levels of mortality
    }
    else { # agegroup==5 and startage > 0
        ax <- c(rep(2.6, nn - 1), Inf)
        nx <- c(rep(5, nn))
    }
    qx <- nx * mx/(1 + (nx - ax) * mx)
   # age <- startage + cumsum(nx) - 1
   # if (max(age) >= 75) {
    #    idx <- (age >= 75)
     #   ax[idx] <- (1/mx + nx - nx/(1 - exp(-nx * mx)))[idx]
      #  qx[idx] <- 1 - exp(-nx * mx)[idx]
    #    }
    #qx[qx > 1] <- 1  ################  NOT NEEDED IN THEORY

#plot(qx)  #### TO CHECK RESULT RE QX>1

    qx[nn] <- 1
    if (nn > 1) {
        lx <- c(1, cumprod(1 - qx[1:(nn - 1)]))
        dx <- -diff(c(lx, 0))
    }
    else lx <- dx <- 1
    Lx <- nx * lx - dx * (nx - ax)
    Lx[nn] <- lx[nn]/mx[nn]
    Tx <- rev(cumsum(rev(Lx)))
    ex <- Tx/lx
    if (nn > 2)
        rx <- c(Lx[1]/lx[1], Lx[2:(nn - 1)]/Lx[1:(nn - 2)], Tx[nn]/Tx[nn-1])
    else if (nn == 2)
        rx <- c(Lx[1]/lx[1], Tx[nn]/Tx[nn - 1])
    else rx <- c(Lx[1]/lx[1])
    if (agegroup == 5)
        rx <- c(0, (Lx[1] + Lx[2])/5 * lx[1], Lx[3]/(Lx[1]+Lx[2]),
                Lx[4:(nn - 1)]/Lx[3:(nn - 2)], Tx[nn]/Tx[nn-1])
    result <- data.frame(ax = ax, mx = mx, qx = qx, lx = lx,
        dx = dx, Lx = Lx, Tx = Tx, ex = ex, rx = rx, nx = nx)
    return(result)
}

plot.lifetable <- function(x,years=x$year,main,xlab="Age",ylab="Expected number of years left",...)
{
	if(x$type != "period")
		stop("Currently only period lifetables can be plotted.")
    # Extract years
    idx <- match(years,x$year)
    idx <- idx[!is.na(idx)]
    idx <- idx[idx <= ncol(x$ex)]
    if(length(idx)==0)
        stop("Year not available")
    years <- x$year[idx]
    ny <- length(years)

    if(missing(main))
    {
        main <- paste("Life expectancy:",x$label,x$series)
        if(ny>1)
            main <- paste(main," (",min(years),"-",max(years),")",sep="")
        else
            main <- paste(main," (",years,")",sep="")
    }

    plot(fts(x$age,x$ex[,idx],start=years[1],frequency=1),main=main,ylab=ylab,xlab=xlab,...)
}

lines.lifetable <- function(x,years=x$year,...)
{
	if(x$type != "period")
		stop("Currently only period lifetables can be plotted.")
    # Extract years
    idx <- match(years,x$year)
    idx <- idx[!is.na(idx)]
    idx <- idx[idx <= ncol(x$ex)]
    if(length(idx)==0)
        stop("Year not available")
    years <- x$year[idx]
    ny <- length(years)

    lines(fts(x$age,x$ex[,idx],start=x$year[1],frequency=1),...)
}

print.lifetable <- function(x,digits=4,...)
{
	ny <- ncol(x$ex)
    outlist <- vector(length=ny,mode="list")
    for(i in 1:ny)
    {
        idx2 <- !is.na(x$mx[,i])
        if(sum(idx2)>0)
        {
            outlist[[i]] <- data.frame(x$mx[,i],x$qx[,i],x$lx[,i],x$dx[,i],x$Lx[,i],x$Tx[,i],x$ex[,i])[idx2,]
            rownames(outlist[[i]]) <- rownames(x$ex)[idx2]
            colnames(outlist[[i]]) <- c("mx","qx","lx","dx","Lx","Tx","ex")
        }
    }
	if(x$type=="period")
	{
		names(outlist) = x$year
		cat("Period ")
	}
    else
	{
		names(outlist) <- colnames(x$ex)
        cat("Cohort ")
	}
    cat(paste("lifetable for",x$label,":",x$series,"\n\n"))
    for(i in 1:ny)
    {
        if(!is.null(outlist[[i]]))
        {
            if(x$type=="period")
                cat(paste("Year:",names(outlist)[i],"\n"))
            else
                cat(paste("Cohort:",names(outlist)[i],"\n"))
            print(round(outlist[[i]],digits=digits))
            cat("\n")
        }
    }
    invisible(outlist)
}



# Compute expected age from single year mortality rates
get.e0 <- function(x,agegroup,sex,startage=0)
{
    lt(x, startage, agegroup, sex)$ex[1]
}

# Compute expected ages for multiple years
life.expectancy <- function(data,series=names(data$rate)[1],years=data$year,
    type=c("period","cohort"), age=min(data$age), max.age=min(100,max(data$age)))
{
    type <- match.arg(type)
    if(!is.el(series,names(data$rate)))
        stop(paste("Series",series,"not found"))
	if(is.null(max.age))
		max.age <- min(100,max(data$age))
    if(age > max.age | age > max(data$age))
        stop("age is greater than maximum age")
    else if(age < min(data$age))
        stop("age is less than minimum age")
    if(type=="period")
		data.lt <- lifetable(data,series,years,type=type,max.age=max.age)$ex
	else
		data.lt <- lifetable(data,series,years,type=type,ages=age,max.age=max.age)$ex
    idx <- match(age,rownames(data.lt))
    #if(sum(is.na(data.lt[idx,]))>0 | max(data.lt[idx,]) > 1e9)
    #    warning("Some missing or infinite values in the life table calculation.\n  These can probably be avoided by setting max.age to a lower value.")

    return(ts(data.lt[idx,],start=years[1],frequency=1))
}


flife.expectancy <- function(data, series=NULL, years=data$year,
    type=c("period","cohort"), age=min(data$age), max.age=NULL,
	PI=FALSE, nsim=500, ...)
{
    type <- match.arg(type)
    if(is.element("fmforecast",class(data)))
    {
		if(data$type != "mortality")
			stop("data not a mortality object")
        hdata <- list(year=data$model$year,age=data$model$age,
            type=data$type,label=data$model$label,lambda=data$lambda)
        hdata$rate <- list(data$model[[4]])
		if(min(hdata$rate[[1]],na.rm=TRUE) < 0) # Transformed
		    hdata$rate <- list(InvBoxCox(hdata$rate[[1]],data$lambda))
        if(type=="cohort")
        {
            hdata$year <- c(hdata$year,data$year)
            hdata$rate <- list(cbind(hdata$rate[[1]],data$rate[[1]]))
        }
        names(hdata$rate) <- names(data$model)[4]
		if(!is.null(data$model$pop))
		{
		    hdata$pop = list(data$model$pop)
			names(hdata$pop) <- names(hdata$rate)
            if(type=="cohort") # Add bogus population for future years
            {
                n <- ncol(hdata$pop[[1]])
                h <- length(hdata$year)-n
                hdata$pop[[1]] <- cbind(hdata$pop[[1]],matrix(rep(hdata$pop[[1]][,n],h),nrow=nrow(hdata$pop[[1]]),ncol=h))
            }
		}
        class(hdata) <- "demogdata"
        # Fix missing values. Why are they there?
        hdata$rate[[1]][is.na(hdata$rate[[1]])] <- 1-1e-5
		if(is.null(max.age))
			max.age <- min(100,max(data$age))

        x <- window(life.expectancy(hdata,type=type,age=age,max.age=max.age),end=max(data$model$year))
        xf <- na.omit(life.expectancy(data,years=years,type=type,age=age,max.age=max.age))
        if(type=="cohort")
        {
            xf <- ts(c(window(x,start=max(data$model$year)-max.age+age+1),xf),end=max(time(xf)))
            if(min(time(x)) > max(data$model$year)-max.age+age)
                x <- ts(NA,end=min(time(xf))-1)
            else
                x <- window(x,end=max(data$model$year)-max.age+age)
        }

        out <- structure(list(x=x,mean=xf,method="FDM model"),class="forecast")
		if(is.element("lca",class(data$model)))
			out$method = "LC model"
		else if(!is.null(data$product))
			out$method = "Coherent FDM model"
		if(PI) # Compute prediction intervals
		{
			e0calc <- (!is.element("product",names(data$rate)) & !is.element("ratio",names(data$rate)))
			if(is.null(data$product) & is.null(data$var) & is.null(data$kt.f))
				warning("Incomplete information. Possibly this is from a coherent\n  model and you need to pass the entire object.")
			else
			{
				sim <- simulate(data,nsim,...)
                if(type=="cohort") # Add actual rates for first few years
                {
                    usex <- length(x)*any(!is.na(x))
                    ny <- length(data$model$year) - usex
                    sim2 <- array(NA,c(dim(sim)[1],dim(sim)[2]+ny,dim(sim)[3]))
                    sim2[,(ny+1):dim(sim2)[2],] <- sim
                    hrates <- hdata$rate[[1]][,usex + (1:ny)]
                    sim2[,1:ny,] <- array(rep(hrates,dim(sim)[2]),c(dim(sim)[1],ny,dim(sim)[3]))
                    sim <- sim2
                    rm(sim2)
                }
				if(e0calc)
				{
					e0sim <- matrix(NA,dim(sim)[2],dim(sim)[3])
					simdata <- data
                    if(type=="cohort")
                        simdata$year <- min(time(out$mean))-1 + 1:dim(sim)[2]
					for(i in 1:dim(sim)[3])
					{
						simdata$rate <- list(as.matrix(sim[,,i]))
                        names(simdata$rate) <- names(data$rate)[1]
						e0sim[,i] <- life.expectancy(simdata,type=type,age=age,max.age=max.age)
					}
					if(is.element("lca",class(data$model)))
						out$level <- data$kt.f$level
					else
						out$level <- data$coeff[[1]]$level
					out$lower <- na.omit(ts(apply(e0sim,1,quantile,prob=0.5 - out$level/200,na.rm=TRUE)))
					out$upper <- na.omit(ts(apply(e0sim,1,quantile,prob=0.5 + out$level/200,na.rm=TRUE)))
					tsp(out$lower) <- tsp(out$upper) <- tsp(out$mean)
				}
				out$sim <- sim
			}
		}
		return(out)
    }
	else if(is.element("fmforecast2",class(data)))
	{
		if(data[[1]]$type != "mortality")
			stop("data not a mortality object")
		if(is.null(series))
			series <- names(data)[1]
		if(is.null(max.age))
			max.age <- min(100,max(data[[series]]$age))
		if(is.element("product",names(data))) # Assume coherent model
		{
			out <- flife.expectancy(data[[series]],PI=FALSE,age=age,max.age=max.age,type=type)
			if(max.age < 0)
				max.age <- min(100,max(data[[series]]$age))
			if(PI)
			{
				prodsim <- flife.expectancy(data$product,nsim=nsim,PI=PI,age=age,max.age=max.age,type=type)
				ratiosim <- flife.expectancy(data$ratio[[series]],nsim=nsim,PI=PI,age=age,max.age=max.age,type=type)
				sim <- prodsim$sim * ratiosim$sim
				e0sim <- matrix(NA,dim(sim)[2],dim(sim)[3])
				simdata <- data[[series]]
				for(i in 1:dim(sim)[3])
				{
					simdata$rate[[1]] <- as.matrix(sim[,,i])
					e0sim[,i] <- life.expectancy(simdata,type=type,age=age,max.age=max.age)
				}
				out$level <- data$product$coeff[[1]]$level
				out$lower <- ts(apply(e0sim,1,quantile,prob=0.5 - out$level/200))
				out$upper <- ts(apply(e0sim,1,quantile,prob=0.5 + out$level/200))
				tsp(out$lower) <- tsp(out$upper) <- tsp(out$mean)
			}
		}
		else
			out <- flife.expectancy(data[[series]],PI=PI,nsim=nsim,max.age=max.age,type=type,age=age)
		return(out)
	}
    else
	{
	    if(!is.element("demogdata",class(data)))
			stop("data must be a demogdata object")
		if(data$type != "mortality")
			stop("data must be a mortality object")
		if(is.null(series))
			series <- names(data$rate)[1]
        return(life.expectancy(data,series=series,years=years,type=type,age=age,max.age=max.age))
	}
}

e0 <- function(data, series=NULL, years=data$year,
    type=c("period","cohort"), max.age=NULL,
	PI=FALSE, nsim=500, ...)
{
	flife.expectancy(data, series=series, years=years,age=0,
		type=type, max.age=max.age,PI=PI,nsim=nsim,...)
}
