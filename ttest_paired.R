# Test de moyenne - T test simulation (Monte Carlo)
# Objectif: Estimation de puissance 
# dans le cas: 2 échantillons appariés

# Clear environment
rm(list=ls())
library(gplots)

#-----------------------------------------------------------------------
# Paramètres de la simulation
#-----------------------------------------------------------------------

## Pilote

# Taille des échantillons pilotes
npilote = 20
# Nombre de runs pour le Bootstrap du pilote,
# servant à estimer un intervalle de confiance pour l'écart-type du pilote
runs_bs_pilote = 1000
# Difference between the means
# no difference to test the alpha level (type I errors)
meand = 0
# non null to test how often the existing effect is found (power)
meand = 0.03
# Standard deviation of samples
s1 = 0.1
s2 = 0.05
# correlation factor
cf = 0.6
# Erreur de 1ère espèce
alpha = 0.05

## Monte Carlo

# Intervalle des tirages pour Monte-Carlo.
# On prend les mêmes tailles de tirage pour les 2 échantillons
tailles = 10*(2:10)
# Number of runs for MC
runs_MC = 1000


#---------------------------------------------------
#                     pilote 
#---------------------------------------------------



pilote_ttest_paired<-function(npilote, meand, s1, s2, cf, runs_bs_pilote, dest_pilote)
{
  alpha = 0.05
  # On simule 2 échantillons "réels"
  # tels que: leur différence de moyenne est meand,
  # les standard error des echantillons sont s1 et s2,
  # et le facteur de corrélation est cf.
  congruent = rnorm(npilote,mean = 0,sd = s1)
  # Dans le cas apparié, on suppose que Y = a + bX + eps,
  # où eps est une normale centrée. On a donc:
  a = meand
  # puis var(Y) = b²var(X) + var(eps), et
  # cf = b/(s1s2)
  b = cf*(s1*s2)
  sd_eps = sqrt(s2^2-b^2*s1^2)  
  eps = rnorm(npilote,mean = 0,sd = sd_eps)
  incongruent = a + b*congruent + eps
  # On estime les paramètres du pilote
  mean1 = mean(congruent)
  mean2 = mean(incongruent)
  meand2 = mean2 - mean1
  ecart_type_congruent = sd(congruent)
  ecart_type_incongruent = sd(incongruent)
  cf_estime = cor(congruent, incongruent)
  # On détermine l'intervalle de confiance pour la moyenne du ttest
  conf_mean = t.test(incongruent,congruent,paired = TRUE)$conf.int
  # On détermine l'intervalle de confiance des écarts-type et du coefficient de corrélation avec un Bootstrap
  table_sd1 = numeric(runs_bs_pilote)
  table_sd2 = numeric(runs_bs_pilote)
  for(i in 1:runs_bs_pilote)
  {
    # On choisit pour le boostrap des sous-ensembles de taille 80% de la taille de l'échantillon 
    n_bs = ceiling(0.8*npilote)
    table_sd1[i] = sd((sample(congruent,n_bs,replace=T)))
    table_sd2[i] = sd((sample(incongruent,n_bs,replace=T)))
  }
  table_sd1_sorted = sort(table_sd1)
  table_sd2_sorted = sort(table_sd2)
  conf_sd1 = c(table_sd1_sorted[floor(runs_bs_pilote*alpha)],table_sd1_sorted[floor(runs_bs_pilote*(1-alpha))])
  conf_sd2 = c(table_sd2_sorted[floor(runs_bs_pilote*alpha)],table_sd2_sorted[floor(runs_bs_pilote*(1-alpha))])
  # On trace le pilote
  jpeg(dest_pilote)
  densCongruent <- density(congruent)
  densIncongruent <- density(incongruent)
  histCongruent <-hist(congruent, breaks=10, plot = FALSE)
  histIncongruent <- hist(incongruent, breaks=10, plot = FALSE)
  xlim <- range(histIncongruent$breaks,histCongruent$breaks)
  ylim <- range(0,histIncongruent$density,histCongruent$density)
  #ylim <- c(0,max(histCongruent$density,max(histIncongruent$density)))
  plot(histCongruent,xlim = xlim, ylim = ylim,
       col = rgb(1,0,0,0.4),xlab = 'congruent',
       freq = FALSE, ## relative, not absolute frequency
       main = 'Distribution')
  opar <- par(new = FALSE)
  plot(histIncongruent,xlim = xlim, ylim = ylim,
       xaxt = 'n', yaxt = 'n', ## don't add axes
       col = rgb(0,0,1,0.4), add = TRUE,
       freq = FALSE) ## relative, not absolute frequency
  ## add a legend in the corner
  legend('topleft',c('Congruent','Incongruent'),
         fill = rgb(1:0,0,0:1,0.4), bty = 'n',
         border = NA)
  par(opar)
  ## plot first density
  xfit1<-seq(min(congruent),max(congruent),length=40)
  yfit1<-dnorm(xfit1,mean=mean1,sd=ecart_type_congruent)
  yfit1 <- yfit1*diff(histCongruent$mids[1:2])*length(congruent)
  lines(xfit1, yfit1, col=rgb(1,0,0,0.4), lwd=2) 
  ## plot second density
  xfit2<-seq(min(incongruent),max(incongruent),length=40)
  yfit2<-dnorm(xfit2,mean=mean2,sd=ecart_type_incongruent)
  yfit2 <- yfit2*diff(histIncongruent$mids[1:2])*length(incongruent)
  lines(xfit2, yfit2, col=rgb(0,0,1,0.4), lwd=2) 
  
  
  dev.off()
  # On retourne l'approximation de l'étude pilote
  return (list(ecart_type_congruent=ecart_type_congruent, ecart_type_incongruent=ecart_type_incongruent, mean=meand2, conf_mean=conf_mean, conf_sd1=conf_sd1,conf_sd2 = conf_sd2))
}



#---------------------------------------------------
# Monte-Carlo pour 2 échantillons appariés 
#---------------------------------------------------

MC<-function(n, runs, meand, s1, s2, cf){
  alpha = 0.05
  # Independent variable (predictor)
  x = c(
    rep(1,n)	# group 
  )
  x = factor(x)
  
  # Perform runs (with stochastic sampling)
  tval = numeric(runs) # to store resulting t statistics
  tval_hand = numeric(runs) # to store resulting t statistics (computed by hand)
  pval = numeric(runs) # to store resulting p-values
  
  sz = sqrt(s1^2+s2^2-(2*cf*s1*s2))
  
  for (r in 1:runs) {
    # Generate random independent samples with normal distributions
    # for the dependent variable (predicted)
    y = c(
      rnorm(n,mean=meand,sd=sz)
    )
    
    # Run model : on stocke les t-statistics et p-values
    # du modèle généré par R.
    model = t.test(y)
    tval[r] = model$statistic
    pval[r] = model$p.value
    
    # Hand-made equivalent to compute the t statistic
    # (will produce the same value as model$statistic)
    # DV for group
    y1 = y[x==1]
    # Pooled standard deviation
    s12 = sd(y1)
    tval_hand[r] = mean(y1)/(s12/sqrt(n))
  }
  
  # Display the resulting statistics
  res = data.frame(
    t_statistic=tval,
    t_statistic_hand=tval_hand,
    p_value=pval
  )
  head(res,10)
  

  # Directly exploit the pvalues generated by the model
  # to get the power of type I error rate (depending on meand value)
  # p5_model devrait tendre vers 0.05 si meand = 0
  # p5_model nous donne la puissance du test si meand != 0
  nb = sum(pval<alpha)
  # --> signifie que si meand = 0, on conclue à tort un effet à un ratio p5_model
  # si meand != 0, on affirme à raison un effet à un ratio p5_model
  p5_model = nb/runs
  
  # Compute the ratio of type I errors (should be <0.5)
  # equivalent to what precedes (to help you understand the computations)
  # (using the t statistic table/function)
  # p5_hand devrait etre égal à p5_model
  thr_low = qt(alpha/2,n+n-2,lower.tail=T)
  thr_upp = qt(alpha/2,n+n-2,lower.tail=F)
  nb = sum(tval<thr_low | tval>thr_upp)
  p5_hand = nb/runs
  
  # On calcule la puissance théorique (analytique) du t-test avec le package power:
  # NB: Dans le cas n1 = n2 = n, on devrait avoir p5_package = p5_model = p5_hand.
  p5_package = power.t.test(n=n, d = (meand)/sz, sig.level = alpha, type = "paired", alternative = "two.sided")$power
  
  return(list(meand = meand, sd = sd, p5_model = p5_model, p5_hand = p5_hand, p5_package = p5_package ))
}


#---------------------------------------------------
# t-test simulations (Monte-Carlo)
#---------------------------------------------------

ttest_paired<-function(n,runs, pilote,cf){
  
  # On récupère les informations du pilote
  # Pour la moyenne
  mean = pilote$mean # moyenne empirique du pilote
  conf_mean = pilote$conf_mean # intervalle de confiance pour la moyenne du pilote au seuil alpha = 0.05
  # Bornes de l'intervalle de confiance de la moyenne
  meaninf = conf_mean[1]
  meansup = conf_mean[2]
  # Pour les écarts-type
  ecart_type1 = pilote$ecart_type_congruent 
  ecart_type2 = pilote$ecart_type_incongruent
  conf_sd1 = pilote$conf_sd1
  conf_sd2 = pilote$conf_sd2
  # Bornes des intervalles de confiance des écarts-type
  sd1inf = conf_sd1[1]
  sd1sup = conf_sd1[2]
  sd2inf = conf_sd2[1]
  sd2sup = conf_sd2[2]
  MC_inf = MC(n,runs,meaninf,sd1sup,sd2sup,cf)
  MC_sup = MC(n,runs,meansup,sd1inf,sd2inf,cf)
  MC_moy = MC(n,runs,mean,ecart_type1,ecart_type2,cf)
  
  IC_Puissance_model = c(MC_inf$p5_model,MC_sup$p5_model)
  IC_Puissance_hand = c(MC_inf$p5_hand,MC_sup$p5_hand)
  IC_Puissance_package = c(MC_inf$p5_package,MC_sup$p5_package)
  
  # On présente les résultats sur la puissance:
  # La puissance à partir des paramètres empiriques du pilote, 
  # Puis les intervalles de confiance de la puissance calculés
  # à partir des intervalles de confiance des paramètres.
  # NB : 
  Puissance_moy_hand = MC_moy$p5_hand
  Puissance_moy_model = MC_moy$p5_model
  Puissance_moy_package = MC_moy$p5_package
  results = data.frame(
    n=n,
    runs = runs,
    Puissance_moy_hand = Puissance_moy_hand,
    IC_Puissance_hand_inf = IC_Puissance_hand[1],
    IC_Puissance_hand_sup = IC_Puissance_hand[2],
    Puissance_moy_model = Puissance_moy_model,
    IC_Puissance_model_inf = IC_Puissance_model[1],
    IC_Puissance_model_sup = IC_Puissance_model[2],
    Puissance_moy_package = MC_moy$p5_package,
    IC_Puissance_package_inf = IC_Puissance_package[1],
    IC_Puissance_package_sup = IC_Puissance_package[2]
  )
  return (results)
}

#---------------------------------------------------
# Test : Puissance en fonction de la taille de l'échantillon.
# (Calcul basé sur l'algorithme de Monte Carlo )
#---------------------------------------------------

TEST_ap<-function(npilote = 20, meand = 0.1, s1 = 0.3, s2 = 0.3, cf = 0.6, runs_bs_pilote = 1000, runs_MC = 1000, taille_max = 100, dest_puissance, dest_pilote, puissance = NULL){
  # Environment
  library(gplots)
  # Création du pilote
  pilote = pilote_ttest_paired(npilote, meand, s1, s2, cf, runs_bs_pilote, dest_pilote)
  # On regarde la puissance en fonction de la taille d'échantillon
  # (!= npilote, qui est la taille du pilote.
  # ici, la taille de l'échantillon correspond à la taille des tirages pour Monte-Carlo)
  tailles = seq(from = 20, to = taille_max, length.out = 15)
  longueur = length(tailles)
  puissances =numeric(longueur)
  IC_low_width = numeric(longueur)
  IC_up_width = numeric(longueur)
  for (i in 1:longueur){
    results = ttest_paired(tailles[i],runs_MC,pilote,cf)
    puissances[i] = results$Puissance_moy_hand
    IC_low_width[i] =  puissances[i] - results$IC_Puissance_hand_inf
    IC_up_width[i] = results$IC_Puissance_hand_sup - puissances[i]
  }
  jpeg(dest_puissance)
  plotCI(tailles, puissances, uiw = IC_up_width, liw = IC_low_width, type = "o", barcol = "red")
  dev.off()
  results # affiche les puissances pour le dernier tirage de Monte Carlo
}
n = TEST_ap(dest_puissance =  '/user/6/.base/bonjeang/home/SpeProject/Projet-Specialite-Calcul-de-Puissance/TEST/puissance.jpg',
         dest_pilote = '/user/6/.base/bonjeang/home/SpeProject/Projet-Specialite-Calcul-de-Puissance/TEST/pilote.jpg',puissance = 0.8)
n
