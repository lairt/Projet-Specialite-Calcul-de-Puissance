# Test de régression multiple
# Objectif: Estimation de puissance des paramètres
# dans le cas: régression multiple


# Environment

library(gplots)
library(regression)
library(boot)

#-----------------------------------------------------------------------
# Paramètres de la simulation
#-----------------------------------------------------------------------


# Erreur de 1ère espèce
alpha = 0.05

## Monte Carlo
b_0 = 1
b_1 = 1
b_2 = 1
noise_s = 0.5
npilote = 20
n = 40
runs = 1000
runs_bs_pilote = 1000
# Intervalle des tirages pour Monte-Carlo.
# On prend les mêmes tailles de tirage pour les 2 échantillons
tailles = 10*(2:10)
# Number of runs for MC
runs_MC = 1000



#---------------------------------------------------
#                     pilote 
#---------------------------------------------------

stat_b_0<-function(data, indice){
  model = lm(data[indice,3]~data[indice,1:2])
  return (summary(model)[[4]][[1]])
}

stat_b_1<-function(data, indice){
  model = lm(data[indice,3]~data[indice,1:2])
  return (summary(model)[[4]][[2]])
}
stat_b_2<-function(data, indice){
  model = lm(data[indice,3]~data[indice,1:2])
  return (summary(model)[[4]][[3]])
}

stat_noise_s<-function(data, indice){
  model = lm(data[indice,3]~data[indice,1:2])
  return (summary(model)$sigma)
}

# Fonction qui génère un échantillon pilote et renvoie l'échantillon et
# l'intervalle de confiance des 2 paramètres estimé b_0 et b_1
pilote_multiple_reg<-function(npilote, runs_bs_pilote, b_0, b_1, b_2, noise_s, dest_pilote)
{
  # On simule 1 échantillon "réel"
  # Si tous les paramètres ne sont pas rentrés,
  # alors ils seront simulés aléatoirement
  # par la fonction regression_blind
  if (is.null(b_0) | is.null(b_1) | is.null(b_2) |  is.null(noise_s)){
    print("Génération d'un pilote aux paramètres aléatoires pour régression multiple")
    reg = regression_blind(2, npilote)
    # estimation of parameters
    x = reg$x
    Y = reg$Y
    x = matrix(x,nrow = npilote,ncol = 2)
    model = lm(Y~x)
    } else {
    # b0, b1 et noise_s doivent être de taille 1
    try(if(length(b_0) != 1 | length(b_1) != 1 | length(b_2) != 1 | length(noise_s) != 1) stop("b0,b1,b2 et noise_s doivent être de taille 1"))
    # sinon on simule le pilote avec les paramètres souhaités.
    reg = multiple_regression(npilote, b_0, b_1, b_2, noise_s)
    # estimation of parameters
    x = reg$x
    Y = reg$Y
    x = x[,-1]
    model = lm(Y~x)
  }

  sum = summary(model)
  b0 = sum[[4]][[1]]
  b1 = sum[[4]][[2]]
  b2 = sum[[4]][[3]]
  noises = sum$sigma
  data = cbind(x,Y)
  # bootstrapping to determine confidence intervals for paramaters 
  boot_b_0 <- boot(data=data, statistic=stat_b_0, R=runs_bs_pilote)
  boot_b_1 <- boot(data=data, statistic=stat_b_1, R=runs_bs_pilote)
  boot_b_2 <- boot(data=data, statistic=stat_b_2, R=runs_bs_pilote)
  boot_noise_s <- boot(data=data, statistic=stat_noise_s, R=runs_bs_pilote)
  c_0 = boot.ci(boot_b_0, type="bca")$bca
  c_1 = boot.ci(boot_b_1, type="bca")$bca
  c_2 = boot.ci(boot_b_2, type="bca")$bca
  c_s = boot.ci(boot_noise_s, type="bca")$bca
  conf_b_0 = c(c_0[4],c_0[5])
  conf_b_1 = c(c_1[4],c_1[5])
  conf_b_2 = c(c_2[4],c_2[5])
  conf_noise_s = c(c_s[4],c_s[5])
  plot_mod(x[,2], Y, dest_pilote)
  return (list(b_0=b0,b_1=b1,b_2=b2,noise_s=noises,conf_b_0=conf_b_0,conf_b_1=conf_b_1,conf_b_2=conf_b_2,conf_noise_s=conf_noise_s))
}

# Fonction qui permet de tracer l'échantillon pilote, la droite de régression et les intervalles de confiance/prédiction
plot_mod<-function(x, Y, dest_pilote){
  model <- lm(Y~x)
  jpeg(dest_pilote)
  plot(x,Y)
  abline(model)
  segments(x,fitted(model),x, Y)
  f = floor(min(x))
  c = ceiling(max(x))
  pred.frame<-data.frame(x=seq(f,c,length.out = 5))
  pc<-predict(model, interval="confidence", newdata=pred.frame)
  pp<-predict(model, interval="prediction", newdata=pred.frame)
  matlines(pred.frame, pc[,2:3], lty=c(2,2), col="blue")
  matlines(pred.frame, pp[,2:3], lty=c(3,3), col="red")
  legend("topleft",c("confiance","prediction"),lty=c(2,3), col=c("blue","red"))
  dev.off()
}

#---------------------------------------------------
# Monte-Carlo pour régression univariée
#---------------------------------------------------

MC<-function(alpha = 0.05, n, runs, b_0, b_1, b_2, noise_s){
  
  # to store resulting p-values from model
  pval0 = numeric(runs) 
  pval1 = numeric(runs) 
  pval2 = numeric(runs) 
  tval_hand = numeric(runs) # to store resulting statisics calculated "by hand"
  for (r in 1:runs) {
    reg = multiple_regression(n, b_0, b_1, b_2, noise_s)
    sum = reg$sum
    # Run model : on stocke les p-values
    # du modèle généré par R.
    pval0[r] = sum[[4]][[10]]
    pval1[r] = sum[[4]][[11]]
    pval2[r] = sum[[4]][[12]]
  }
  # On détermine la puissance empirique du test d'après les p-values trouvées par le modèle de régression
  p5_model_0 = sum(pval0<alpha)/runs
  p5_model_1 = sum(pval1<alpha)/runs
  p5_model_2 = sum(pval2<alpha)/runs
  return(list(p5_model_0 = p5_model_0, p5_model_1 = p5_model_1, p5_model_2 = p5_model_2))
}


#---------------------------------------------------
# test simulation (Monte-Carlo)
#---------------------------------------------------


test_multiple<-function(alpha = 0.05, n, runs, pilote){
  
  # On récupère les informations du pilote
  conf_b_0 = pilote$conf_b_0
  conf_b_1 = pilote$conf_b_1
  conf_b_2 = pilote$conf_b_2
  conf_noise_s = pilote$conf_noise_s
  # Bornes de l'intervalle de confiance des paramètres estimés
  b_0inf = conf_b_0[1]
  b_0sup = conf_b_0[2]
  b_1inf = conf_b_1[1]
  b_1sup = conf_b_1[2] 
  b_2inf = conf_b_2[1]
  b_2sup = conf_b_2[2]
  noise_sinf = conf_noise_s[1]
  noise_ssup = conf_noise_s[2]
  # Paramètres estimés
  b_0 = pilote$b_0
  b_1 = pilote$b_1
  b_2 = pilote$b_2
  noise_s = pilote$noise_s
  MC_inf = MC(n = n,runs = runs,b_0 = b_0inf,b_1 = b_1inf,b_2 = b_2inf,noise_s = noise_ssup)
  MC_moy = MC(n = n,runs = runs,b_0 = b_0,b_1 = b_1,b_2 = b_2,noise_s = noise_s)
  MC_sup = MC(n = n,runs = runs,b_0 = b_0sup,b_1 = b_1sup,b_2 = b_2sup,noise_s = noise_sinf)
  
  
  IC_Puissance_model_0 = c(MC_inf$p5_model_0,MC_sup$p5_model_0)
  IC_Puissance_model_1 = c(MC_inf$p5_model_1,MC_sup$p5_model_1)
  IC_Puissance_model_2 = c(MC_inf$p5_model_2,MC_sup$p5_model_2)
  Puissance_moy_model_0 = MC_moy$p5_model_0
  Puissance_moy_model_1 = MC_moy$p5_model_1
  Puissance_moy_model_2 = MC_moy$p5_model_2
  results = data.frame(
    n=n,
    runs = runs,
    Puissance_moy_model_0 = Puissance_moy_model_0,
    Puissance_moy_model_1 = Puissance_moy_model_1,
    Puissance_moy_model_2 = Puissance_moy_model_2,
    IC_Puissance_model_0_inf = IC_Puissance_model_0[1],
    IC_Puissance_model_0_sup = IC_Puissance_model_0[2],
    IC_Puissance_model_1_inf = IC_Puissance_model_1[1],
    IC_Puissance_model_1_sup = IC_Puissance_model_1[2],
    IC_Puissance_model_2_inf = IC_Puissance_model_2[1],
    IC_Puissance_model_2_sup = IC_Puissance_model_2[2]
  )
  return (results)
}


#---------------------------------------------------
# Test : Puissance en fonction de la taille de l'échantillon.
# (Calcul basé sur l'algorithme de Monte Carlo )
#---------------------------------------------------

Puissance_mr<-function(npilote = 20, runs_bs_pilote = 1000, runs_MC = 1000, tailles = 10*(2:10), b_0 = NULL, b_1 = NULL, b_2 = NULL, noise_s = NULL, dest_puissance, dest_pilote, puissance = NULL){
  # Création du pilote
  pilote = pilote_multiple_reg(npilote, runs_bs_pilote, b_0, b_1, b_2, noise_s, dest_pilote)
  # On regarde la puissance en fonction de la taille d'échantillon
  # (!= npilote, qui est la taille du pilote.
  # ici, la taille de l'échantillon correspond à la taille des tirages pour Monte-Carlo)
  longueur = length(tailles)
  puissances = rep(0,longueur)
  IC_low_width = numeric(longueur)
  IC_up_width = numeric(longueur)
  for (i in 1:longueur){
    # On prend les mêmes tailles d'échantillonage pour les tirages de Monte-Carlo
    results = test_multiple(n = tailles[i], runs = runs_MC, pilote = pilote)
    puissances[i] = results$Puissance_moy_model_2
    IC_low_width[i] =  puissances[i] - results$IC_Puissance_model_2_inf
    IC_up_width[i] = results$IC_Puissance_model_2_sup - puissances[i]
  }
  jpeg(dest_puissance)
  plotCI(tailles, puissances, uiw = IC_up_width, liw = IC_low_width, type = "o", barcol = "red")
  dev.off()
  results # affiche les puissances pour le dernier tirage de Monte Carlo
}

n_calc = 
  Puissance_mr(dest_puissance =  '/user/6/.base/bonjeang/home/SpeProject/Projet-Specialite-Calcul-de-Puissance/TEST/puissance.jpg',
               dest_pilote = '/user/6/.base/bonjeang/home/SpeProject/Projet-Specialite-Calcul-de-Puissance/TEST/pilote.jpg',puissance = 0.8)

n_calc


