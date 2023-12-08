:- module(auc,[compute_areas/5,compute_areas_diagrams/5, compute_maxacc/2]).
/* <module> auc

This module computes the Area Under the Receiving Operating Charactersitics and
Precision Recall curves using the method of
Davis, Jesse, and Mark Goadrich. "The relationship between Precision-Recall
and ROC curves."
Proceedings of the 23rd international conference on Machine learning. ACM, 2006.

@author Fabrizio Riguzzi
@license Artistic License 2.0
*/


%! compute_areas(+LG:list,-AUCROC:float,-ROC:list,-AUCPR:float,-PR:list) is det
%
% The predicate takes as input
%* a list LG of pairs probability-literal in asceding order on probability
%where the literal can be an Atom (indicating a positive example) or \+ Atom,
%indicating a negative example while the probability is the probability of
%Atom of being true
%
%The predicate returns
%* AUCROC: the size of area under the ROC curve
%* ROC: the ROC curve as a list of points that are couples of the form x-y
%* AUCPR: the size of the area under the PR curve
%* PR: the PR curve as a list of points that are couples of the form x-y
%
compute_areas(LG,AUCROC,ROC,AUCPR,PR):-
  must_be(list, LG),
  must_be(var, AUCROC),
  must_be(var, ROC),
  must_be(var, AUCPR),
  must_be(var, PR),
  findall(E,member(_- \+(E),LG),Neg),
  length(LG,NEx),
  length(Neg,NNeg),
  NPos is NEx-NNeg,
  keysort(LG,LG1),
  reverse(LG1,LG2),
  compute_pointsroc(LG2,+1e20,0,0,NPos,NNeg,[],ROC),
  hull(ROC,0,0,0,AUCROC),
  compute_aucpr(LG2,NPos,NNeg,AUCPR,PR).

/**

compute_areas_diagrams(+LG:list,-AUCROC:float,-ROC:dict,-AUCPR:float,-PR:dict) is det

The predicate takes as input
* a list LG of pairs probability-literal in asceding order on probability
 where the literal can be an Atom (indicating a positive example) or \+ Atom,
 indicating a negative example while the probability is the probability of
 Atom of being true

The predicate returns
* AUCROC: the size of the area under the ROC curve
* ROC: the ROC curve as a dict that can be visualized with the c3 renderer of
  SWISH
* AUCPR: the size of the area under the PR curve
* PR: the PR curve as a dict that can be visualized with the c3 renderer of SWISH

See http://cplint.lamping.unife.it/example/exauc.pl for an example

*/
compute_areas_diagrams(LG,AUCROC,ROC,AUCPR,PR):-
  must_be(list, LG),
  must_be(var, AUCROC),
  must_be(var, ROC),
  must_be(var, AUCPR),
  must_be(var, PR),
  compute_areas(LG,AUCROC,ROC0,AUCPR,PR0),
  %  write(ROC0),nl,write(PR0),nl,
  ROC = c3{data:_{x:x, rows:[x-'ROC'|ROC0]},
    axis:_{x:_{min:0.0,max:1.0,padding:0.0,
        tick:_{values:[0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]}},
           y:_{min:0.0,max:1.0,padding:_{bottom:0.0,top:0.0},
        tick:_{values:[0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]}}}},
  PR = c3{data:_{x:x, rows:[x-'PR'|PR0]},
    axis:_{x:_{min:0.0,max:1.0,padding:0.0,
        tick:_{values:[0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]}},
           y:_{min:0.0,max:1.0,padding:_{bottom:0.0,top:0.0},
        tick:_{values:[0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]}}}}.

/**

compute_maxacc(+LG:list,-MaxAcc) is det

The predicate takes as input
* a list LG of pairs probability-literal in asceding order on probability
 where the literal can be an Atom (indicating a positive example) or \+ Atom,
 indicating a negative example while the probability is the probability of
 Atom of being true

The predicate returns
* MaxAcc: the maximum obtainable accuracy

See http://cplint.lamping.unife.it/example/exauc.pl for an example

*/
compute_maxacc(LG, MaxAcc) :-
  must_be(list, LG),
  must_be(var, MaxAcc),
  findall(E,member(_- \+(E),LG),Neg), %find all the pairs that contain a negative examples
  length(LG,NEx),
  length(Neg,NNeg),
  NPos is NEx-NNeg,
  keysort(LG,LG1), % ascending order of the pairs on probabilities
  reverse(LG1,LG2), % discending order of the pairs on probabilities
  compute_acc_list(LG2, 0, 0, NPos, NNeg, [], AccList),
  max_list(AccList, MaxAcc).

/**

compute_acc_list(+LG:list, +TP:int, +FP:int, +FN:int, +TN:int, +AccList0:list, -AccList:list) is det

The predicate takes as input
* LG: a list LG of pairs probability-literal in asceding order on probability
 where the literal can be an Atom (indicating a positive example) or \+ Atom,
 indicating a negative example while the probability is the probability of
 Atom of being true
* TP: the current number of true positive examples
* FP: the current number of false positive examples
* FN: the current number of false negative examples
* TN: the current number of true negative examples
* AccList0: the current list of the possible accuracies

The predicate returns
* AccList: a list of all the possible accuracies

*/
compute_acc_list([], TP, FP, FN, TN, AccList0, AccList) :-
  Acc is (TP+TN)/(TP+TN+FP+FN),
  append(AccList0, [Acc], AccList).

compute_acc_list([_P- (\+ _)|T], TP, FP, FN, TN, AccList0, AccList):-!,
  Acc is (TP+TN)/(TP+TN+FP+FN),
  append(AccList0, [Acc], AccListNew),% append the new accuracy (it creates a new list called AccListNew)
  FP1 is FP+1,
  TN1 is TN-1,
  compute_acc_list(T, TP, FP1, FN, TN1, AccListNew, AccList).

compute_acc_list([_P- _|T], TP, FP, FN, TN, AccList0, AccList):-!,
  Acc is (TP+TN)/(TP+TN+FP+FN),
  append(AccList0, [Acc], AccListNew),
  TP1 is TP+1,
  FN1 is FN-1,
  compute_acc_list(T, TP1, FP, FN1, TN, AccListNew, AccList).




compute_pointsroc([],_P0,_TP,_FP,_FN,_TN,P0,P1):-!,
  append(P0,[1.0-1.0],P1).

compute_pointsroc([P- (\+ _)|T],P0,TP,FP,FN,TN,Po0,Po1):-!,
  (P<P0->
    FPR is FP/(FP+TN),
    TPR is TP/(TP+FN),
    append(Po0,[(FPR-TPR)],Po2),
    P1=P
  ;
    Po2=Po0,
    P1=P0
  ),
  FP1 is FP+1,
  TN1 is TN-1,
  compute_pointsroc(T,P1,TP,FP1,FN,TN1,Po2,Po1).

compute_pointsroc([P- _|T],P0,TP,FP,FN,TN,Po0,Po1):-!,
  (P<P0->
    FPR is FP/(FP+TN),
    TPR is TP/(TP+FN),
    append(Po0,[FPR-TPR],Po2),
    P1=P
  ;
    Po2=Po0,
    P1=P0
  ),
  TP1 is TP+1,
  FN1 is FN-1,
  compute_pointsroc(T,P1,TP1,FP,FN1,TN,Po2,Po1).


hull([],FPR,TPR,AUC0,AUC1):-
  AUC1 is AUC0+(1-FPR)*(1+TPR)/2.


hull([FPR1-TPR1|T],FPR,TPR,AUC0,AUC1):-
  AUC2 is AUC0+(FPR1-FPR)*(TPR1+TPR)/2,
  hull(T,FPR1,TPR1,AUC2,AUC1).

compute_aucpr(L,Pos,Neg,A,PR):-
  L=[P_0-E|TL],
  (E= (\+ _ )->
    FP=1,
    TP=0,
    FN=Pos,
    TN is Neg -1
  ;
    FP=0,
    TP=1,
    FN is Pos -1,
    TN=Neg
  ),
  compute_curve_points(TL,P_0,TP,FP,FN,TN,Points),
  Points=[R0-P0|_TPoints],
  (R0=:=0,P0=:=0->
    Flag=true
  ;
    Flag=false
  ),
  area(Points,Flag,Pos,0,0,0,A,[],PR).

compute_curve_points([],_P0,TP,FP,_FN,_TN,[1.0-Prec]):-!,
  Prec is TP/(TP+FP).

compute_curve_points([P- (\+ _)|T],P0,TP,FP,FN,TN,Pr):-!,
  (P<P0->
    Prec is TP/(TP+FP),
    Rec is TP/(TP+FN),
    Pr=[Rec-Prec|Pr1],
    P1=P
  ;
    Pr=Pr1,
    P1=P0
  ),
  FP1 is FP+1,
  TN1 is TN-1,
  compute_curve_points(T,P1,TP,FP1,FN,TN1,Pr1).

compute_curve_points([P- _|T],P0,TP,FP,FN,TN,Pr):-!,
  (P<P0->
    Prec is TP/(TP+FP),
    Rec is TP/(TP+FN),
    Pr=[Rec-Prec|Pr1],
    P1=P
  ;
    Pr=Pr1,
    P1=P0
  ),
  TP1 is TP+1,
  FN1 is FN-1,
  compute_curve_points(T,P1,TP1,FP,FN1,TN,Pr1).

area([],_Flag,_Pos,_TPA,_FPA,A,A,PR,PR).

area([R0-P0|T],Flag,Pos,TPA,FPA,A0,A,PR0,PR):-
 TPB is R0*Pos,
  (TPB=:=0->
    A1=A0,
    FPB=0,
    PR2=PR0,
    PR=[R0-P0|PR3]
  ;
    R_1 is TPA/Pos,
    (TPA=:=0->
      (Flag=false->
        P_1=P0,
	PR=[0.0-P0|PR3]
      ;
        P_1=0.0,
	PR=[0.0-0.0|PR3]
      )
    ;
      P_1 is TPA/(TPA+FPA),
      PR=PR3
    ),
    FPB is TPB*(1-P0)/P0,
    N is TPB-TPA+0.5,
    (N<1.0->
      append(PR0,[R0-P0],PR2),
      A1=A0
    ;
      interpolate(1,N,Pos,R_1,P_1,TPA,FPA,TPB,FPB,A0,A1,[],PR1),
      append(PR0,PR1,PR2)
    )
  ),
  area(T,Flag,Pos,TPB,FPB,A1,A,PR2,PR3).

interpolate(I,N,_Pos,_R0,_P0,_TPA,_FPA,_TPB,_FPB,A,A,PR,PR):-I>N,!.

interpolate(I,N,Pos,R0,P0,TPA,FPA,TPB,FPB,A0,A,PR0,[R-P|PR]):-
  R is (TPA+I)/Pos,
  P is (TPA+I)/(TPA+I+FPA+(FPB-FPA)/(TPB-TPA)*I),
  A1 is A0+(R-R0)*(P+P0)/2,
  I1 is I+1,
  interpolate(I1,N,Pos,R,P,TPA,FPA,TPB,FPB,A1,A,PR0,PR).
