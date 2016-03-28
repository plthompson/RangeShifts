library(vegan)
library(ggplot2)
library(ggExtra)
library(RColorBrewer)
library(dplyr)
library(betalink)
library(igraph)

source("./Functions/plotting_functions.R")


dispV<-c(0.001,0.01,0.5)
reps<-1
dd<-c(0.3,0.2,0.1)#kernel decay strength
FoodWeb<-c("NoInt","Comp","Mixed","Plants","Herb","Pred") 

nCom<-200

Tmax<-3000
burnL<-2000
burn<-rep(1,burnL)
StressV<-c(burn,seq(1,Tmax),rep(Tmax,burnL))
maxStress<-20
Stress<-seq(0,maxStress,(maxStress)/(Tmax-1))
maxEnv1<-80
ComStart<-rev(seq(1,(maxEnv1),(maxEnv1-1)/(nCom-1)))

Disp1<-dist(seq(1:(nCom*2)))
Disp2<-matrix(0,nCom*2,nCom*2)
Disp2[lower.tri(Disp2)]<-Disp1;Disp2[upper.tri(Disp2)]<-rev(Disp1)
Disp<-exp(-dd[1]*Disp2)-diag(nrow(Disp2))
Disp<-Disp[((nCom/2)+1):((nCom/2)+nCom),((nCom/2)+1):((nCom/2)+nCom)]+rbind(apply(Disp[1:(nCom/2),((nCom/2)+1):((nCom/2)+nCom)],2,rev),apply(Disp[((nCom/2)+nCom+1):(nCom*2),((nCom/2)+1):((nCom/2)+nCom)],2,rev))

Disp_pl<-decostand(Disp,"total",2)

Disp<-exp(-dd[2]*Disp2)-diag(nrow(Disp2))
Disp<-Disp[((nCom/2)+1):((nCom/2)+nCom),((nCom/2)+1):((nCom/2)+nCom)]+rbind(apply(Disp[1:(nCom/2),((nCom/2)+1):((nCom/2)+nCom)],2,rev),apply(Disp[((nCom/2)+nCom+1):(nCom*2),((nCom/2)+1):((nCom/2)+nCom)],2,rev))
Disp_h<-decostand(Disp,"total",2)

Disp<-exp(-dd[3]*Disp2)-diag(nrow(Disp2))
Disp<-Disp[((nCom/2)+1):((nCom/2)+nCom),((nCom/2)+1):((nCom/2)+nCom)]+rbind(apply(Disp[1:(nCom/2),((nCom/2)+1):((nCom/2)+nCom)],2,rev),apply(Disp[((nCom/2)+nCom+1):(nCom*2),((nCom/2)+1):((nCom/2)+nCom)],2,rev))
Disp_pr<-decostand(Disp,"total",2)


#competitive
nprey<-80
npred1<-0
npred2<-0

n=nprey+npred1+npred2
weight=1/80*3

b11=-.15
bdiag1=-.2
BB=b11*matrix(runif(nprey*nprey),nprey,nprey)
diag(BB)<-bdiag1
BB=weight*BB
BI<-BB
BN=diag(diag(BB))

C<-rep(0.05,n)

T_Opt<-seq(1,maxEnv1,(maxEnv1-1)/(nprey-1))
T_Norm<-apply(t(T_Opt),2,dnorm,sd=50,x=seq(1,maxStress+maxEnv1))*300
A<-(T_Norm-max(T_Norm))

#mixed
BB<-matrix(-1,n,n)
int.n<-sum(BB[upper.tri(BB)])*-1
BB[upper.tri(BB)][sample(int.n, replace=F)<=(0.35*int.n)]<-0.5
BB[lower.tri(BB)][t(BB)[lower.tri(BB)]>0][sample(0.35*int.n, replace=F)<(0.10*int.n)]<-0.5
BM<-BB*-BI


#tri trophic
nprey<-40
npred1<-24
npred2<-16

preyV<-1:nprey
pred1V<-(nprey+1):(nprey+npred1)
pred2V<-(n-npred2+1):(n)

b11=-0.1
b12=-0.3
b21=0.1
b23=-.1
b32=.08
bdiag1=-.2
bdiag2=-.15


#tritrophic BB Matrix####
B11=b11*matrix(runif(nprey*nprey),nprey,nprey)
B12=b12*matrix(runif(nprey*npred1),nprey,npred1)
B13=matrix(0,nprey,npred2)
B21=b21*matrix(runif(npred1*nprey),npred1,nprey)
B22=matrix(0,npred1,npred1)
B23=b23*matrix(runif(npred1*npred2),npred1,npred2)
B31=matrix(0,npred2,nprey)
B32=b32*matrix(runif(npred2*npred1),npred2,npred1)
B33=matrix(0,npred2,npred2)
BB=rbind(cbind(B11 ,B12, B13),cbind(B21,B22, B23),cbind(B31, B32, B33))
diag(BB)<-bdiag1
diag(BB[(nprey+npred1+1):n,(nprey+npred1+1):n])<-bdiag2
BB=weight*BB

B3<-BB

BN1<-BN
diag(BN1)<-0
BI1<-BI
diag(BI1)<-0
BM1<-BM
diag(BM1)<-0
B31<-B3
diag(B31)<-0

C3<-c(rep(0.05,nprey),rep(0,n-nprey))

T_Opt3<-c(seq(1,maxEnv1,(maxEnv1-1)/(nprey-1)),seq(1,maxEnv1,(maxEnv1-1)/(npred1-1)),seq(1,maxEnv1,(maxEnv1-1)/(npred2-1)))
T_Norm<-apply(t(T_Opt3),2,dnorm,sd=50,x=seq(1,maxStress+maxEnv1))*300
A3<-(T_Norm-max(T_Norm))


for(d in 1:length(dispV)){
  disp<-dispV[d]
  print(d)
  
  XI=array(NA,dim=c(n,length(StressV),nCom))
  XI[,1,]=10
  XM<-X3<-X<-XI
  MeanInteract<-array(NA,dim=c(length(StressV)-1,n,4))
  
  for(l in 1:(length(StressV)-1)){
    X[,l+1,]<-X[,l,]*exp(rep(C,nCom)+BN%*%X[,l,]+t(A[(ComStart+Stress[StressV[l]]),]))+t(Disp_pl%*%t(X[,l,]))*disp-disp*X[,l,]
    X[,l+1,][(X[,l+1,]<10^-3)]<-0
    
    XI[,l+1,]<-XI[,l,]*exp(rep(C,nCom)+BI%*%XI[,l,]+t(A[(ComStart+Stress[StressV[l]]),]))+t(Disp_pl%*%t(XI[,l,]))*disp-disp*XI[,l,]
    XI[,l+1,][(XI[,l+1,]<10^-3)]<-0
    
    X3[preyV,l+1,]<-X3[preyV,l,]*exp(rep(C3[preyV],nCom)+B3[preyV,]%*%X3[,l,]+t(A3[(ComStart+Stress[StressV[l]]),preyV]))+t(Disp_pl%*%t(X3[preyV,l,]))*disp-disp*X3[preyV,l,]
    X3[preyV,l+1,][(X3[preyV,l+1,]<10^-3)]<-0
    X3[pred1V,l+1,]<-X3[pred1V,l,]*exp(rep(C3[pred1V],nCom)+B3[pred1V,]%*%X3[,l,]+t(A3[(ComStart+Stress[StressV[l]]),pred1V]))+t(Disp_h%*%t(X3[pred1V,l,]))*disp-disp*X3[pred1V,l,]
    X3[pred1V,l+1,][(X3[pred1V,l+1,]<10^-3)]<-0
    X3[pred2V,l+1,]<-X3[pred2V,l,]*exp(rep(C3[pred2V],nCom)+B3[pred2V,]%*%X3[,l,]+t(A3[(ComStart+Stress[StressV[l]]),pred2V]))+t(Disp_pr%*%t(X3[pred2V,l,]))*disp-disp*X3[pred2V,l,]
    X3[pred2V,l+1,][(X3[pred2V,l+1,]<10^-3)]<-0
    
    
    XM[,l+1,]<-XM[,l,]*exp(rep(C,nCom)+BM%*%XM[,l,]+t(A[(ComStart+Stress[StressV[l]]),]))+t(Disp_pl%*%t(XM[,l,]))*disp-disp*XM[,l,]
    XM[,l+1,][!is.finite(XM[,l+1,])]<-0
    XM[,l+1,][(XM[,l+1,]<10^-3)]<-0
    
    MeanInteract[l,,1]<-rowMeans(BN1%*%X[,l,])
    MeanInteract[l,,2]<-rowMeans(BI1%*%XI[,l,])
    MeanInteract[l,,3]<-rowMeans(BM1%*%XM[,l,])
    MeanInteract[l,,4]<-rowMeans(B31%*%X3[,l,])
  }
  if(d==1){
    XM1<-XM
    X1<-X3
  } 
  if(d==2){
    X2<-X3
    XM2<-XM
  }
  meta_net_plot(Com = X3,Ints = B3,trophic = T,prop_links = 0.5,interactions = T)
}

pdf("./Figures/Local and regional network change.pdf",width = 11,height = 10)
par(mfrow=c(2,3))
local_net_plot(Com_inits = X1[,2000,],Com_final = X1[,7000,105],Ints = B3,trophic = T,prop_links = 0.5)
local_net_plot(Com_inits = X2[,2000,],Com_final = X2[,7000,105],Ints = B3,trophic = T,prop_links = 0.5)
local_net_plot(Com_inits = X3[,2000,],Com_final = X3[,7000,105],Ints = B3,trophic = T,prop_links = 0.5)

meta_net_plot(Com = X1,Ints = B3,trophic = T,prop_links = 0.5,interactions = T)
meta_net_plot(Com = X2,Ints = B3,trophic = T,prop_links = 0.5,interactions = T)
meta_net_plot(Com = X3,Ints = B3,trophic = T,prop_links = 0.5,interactions = T)
dev.off()