# 2024-12-09: Replaced class/string comparisons with inherits()
#

drop1.uncert<-function(object, scope, simplify=TRUE, 
                which=c("% Change", "var", "u", "var.change", "u.change"), ...) {
        
        if(object$method=="MC") stop("uncertMC objects are not currently supported by drop1.uncert")
        
        which <- if(simplify) match.arg(which) else match.arg(which, several.ok=TRUE)
        #options.which<-eval(formals()$which)
        #if( length( w<-grep(which, options.which) ) >= 1  ) 
        #        which <- options.which[w[1]] 
        #    else 
        #      which <- options.which[1]
	#Removed 2016-07-10 SLRE [causes warning on grep; match simpler]

        x.names<-row.names(object$budget)
        if( missing(scope) ) {
                snames <- x.names
        } else {
                if(inherits(scope, "formula")) {
                        snames<-attr(terms(scope, data=object$cov),"term.labels")
                } else if(inherits(scope, "expression")) {
                        snames<-all.vars(scope)
                } else if(inherits(scope, "character")) {
                        snames <- scope
                }
        
        }
        ci<-object$budget$c
        covmat<-object$cov
        contrib<-outer(ci,ci,"*") * covmat
        sumc<-sum(contrib)
        u.y<-sqrt(sumc)
        rv<-data.frame(row.names=snames)
        rv$u.change<-rv$var.change<-rv$u<-rv$var<-NA
        for(nn in snames) {
                not.x <- !(nn==snames)
                c.nn<-contrib[not.x, not.x]
                rv[nn, "var"]<-sum(c.nn)
                rv[nn, "u"]<-sqrt( rv[nn, "var"] )
                rv[nn, "var.change"] <- rv[nn, "var"]-sumc
                rv[nn, "u.change"] <- rv[nn, "u"]-u.y
        }
        rv[["% Change"]] <- 100*rv[,"u.change"]/u.y
        
        if(!simplify) {
                rv <- rv[ ,names(rv) %in% which, drop=FALSE]
                attr(rv, "expr") <- object$expr
                class(rv)<-c("drop1.uncert", class(rv))
                return(rv)
        } else {
                rvs<-rv[,which[1]]
                names(rvs)<-snames
                return(rvs)
        } 
}

drop1.uncertMC<-function(object, scope, simplify=TRUE, 
                which=c("% Change", "var", "u", "var.change", "u.change"), ...) {
        
        if(is.null(object$MC$x)) stop(sprintf("Missing MC$x in %s: Cannot execute drop", 
                        deparse(substitute(object))), call.=TRUE)
        
        if(any( abs( object$cor[upper.tri(object$cor)] ) > 2*.Machine$double.eps )) {
                stop("Cannot execute drop with correlation present", call.=TRUE)
        }       

        which <- if(simplify) match.arg(which) else match.arg(which, several.ok=TRUE)
        #options.which<-eval(formals()$which)
        #if( length( w<-grep(which, options.which) ) >= 1  ) 
        #        which <- options.which[w[1]] 
        #    else 
        #      which <- options.which[1]
	#Removed 2016-07-10 SLRE [causes warning on grep; match simpler]
	
        x.names<-row.names(object$budget)
        if( missing(scope) ) {
                snames <- x.names
        } else {
                if(inherits(scope, "formula")) {
                        snames<-attr(terms(scope, data=object$cov),"term.labels")
                } else if(inherits(scope, "expression")) {
                        snames<-all.vars(scope)
                } else if(inherits(scope, "character")) {
                        snames <- scope
                }
        
        }
        u.y<-object$u.y
        var.y<-u.y^2
        rv<-data.frame(row.names=snames)
        rv$u.change<-rv$var.change<-rv$u<-rv$var<-NA
        for(nn in snames) {
                mc.x <- object$MC$x
                mc.x[[nn]]<-rep(object$budget[nn,"x"], nrow(mc.x))
                y.nn<-do.call(.apply.expr, c(list(expr=object$expr, x=mc.x), object$additional))
                rv[nn, "var"]<-var(y.nn)
                rv[nn, "u"]<-sqrt( rv[nn, "var"] )
                rv[nn, "var.change"] <- rv[nn, "var"]-var.y
                rv[nn, "u.change"] <- rv[nn, "u"]-u.y
        }
        rv[["% Change"]] <- 100*rv[,"u.change"]/u.y
        
        if(!simplify) {
                attr(rv, "expr") <- object$expr
                class(rv)<-c("drop1.uncert", class(rv))
                return(rv)
        } else {
                rvs<-rv[,which]
                names(rvs)<-snames
                return(rvs)
        } 
}


print.drop1.uncert<-function(x, ..., digits=2) {
                
                expr<-attr(x, "expr")
                cat("Single variable deletions:\n" )
                cat("Expression: ")
                if(inherits(expr, "formula") ) {
                        cat(paste(expr, collapse=""))
                } else if(is.function(expr)) {
                        cat( deparse(expr)[1] )
                } else if(is.expression(expr)) {
                        cat( deparse(expr[[1]]) )
                } else if(is.na(expr)) {
                        cat("NA")
                }
                cat("\n")

                rvf<-format(as.data.frame(x), digits=digits)

                print(rvf, ...)
}

plot.drop1.uncert<-function(x, ..., which=c("% Change", "var", "u", "var.change", "u.change")) {
                
        which <- match.arg(which, several.ok=TRUE)
	
        #Amended 2016-07-11 to loop over all ww in which 
        #Simple loop to get all barplots.
        for(ww in which) {
		pars<-list(...)
		if(is.null(pars$main)) pars$main <- paste( deparse(substitute(x)), "- Single variable deletions")
		if(is.null(pars$ylab)) pars$ylab <- ww

		expr<-attr(x, "expr")
		expr.ch<-
			if(inherits(expr, "formula") ) {
				paste(expr, collapse="")
			} else if(is.function(expr)) {
				deparse(expr)[1] 
			} else if(is.expression(expr)) {
				deparse(expr[[1]]) 
			} else if(is.na(expr)) {
				""
			}

		xv<-x[,ww]
		names(xv)<-row.names(x)

		do.call(barplot, c(list(height=xv), pars))

		mtext(expr.ch, side=3)
        }
        
}


