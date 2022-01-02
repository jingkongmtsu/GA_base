#! /usr/bin/perl
# This script is from the support info of this paper:
# https://pubs.rsc.org/en/content/articlelanding/2017/cp/c7cp00757d#!divAbstract
# Mofifications by jk:
# 1. line up the columns
# 2. Compare multiple sets of data (Change @methods)

use strict;
use warnings;

my $scratch;
my @temp;

my @mol;
my @AT;
my @nAT;
my @Eat;
#my $E_r;
my @reactions;

my $match;
my $count  = -1;
my $rcount = -1;
my $i;
my $j;
my $k;
my $l;
my $ire;
my $ia;
my $ja;
my $bonddiff;

my %educts;
my %products;

my %bondnumber;
my %bondmatrix;
my $name;
my $Nbonds;

my @elements = ("h","he",
                "li","be","b","c","n","o","f","ne",
                "na","mg","al","si","p","s","cl","ar");

my $dobonds = 0;

my @methods = ("ref", "kp14", "mkp16", "mkp16.075");

printf("%54s"," ");
for my $m(@methods) { printf("%12s", $m); }
print "\n";

  if(defined $ARGV[0] and $ARGV[0] eq "bonds"){
    $dobonds = 1;
  }

  if($dobonds == 1){
  open(BOND,"<","bondlist.txt");
    while(<BOND>){
      $scratch=$_ ;
      chomp $scratch ;
      @temp = split / +/, $scratch ;
      $name = $temp[0];
      for($ia=0;$ia<18;$ia++){
        for($ja=0;$ja<18;$ja++){
          $bondmatrix{$name}{$elements[$ia]}{$elements[$ja]} = 0;
        }
      }
      $bondnumber{$name} = $temp[1];
      for($i=0;$i<$bondnumber{$name};$i++){
        $Nbonds = $temp[$i*3+2];
        $bondmatrix{$name}{$temp[$i*3+3]}{$temp[$i*3+4]} += $Nbonds ;
        if($temp[$i*3+3] ne $temp[$i*3+4]){ 
          $bondmatrix{$name}{$temp[$i*3+4]}{$temp[$i*3+3]} += $Nbonds ;
        }
      }
    }
    close BOND;
  }

  open(LIST,"<","reference.txt");
  while(<LIST>){
    $count++;
  # read reference data
    $scratch=$_ ;
    chomp $scratch ;
    @temp = split / +/, $scratch ;
    $mol[$count]    = $temp[0];
    $AT[$count][1]  = $temp[1];
    $AT[$count][2]  = $temp[2];
    $AT[$count][3]  = $temp[3];
    $AT[$count][4]  = $temp[4];
    $nAT[$count][1] = $temp[5];
    $nAT[$count][2] = $temp[6];
    $nAT[$count][3] = $temp[7];
    $nAT[$count][4] = $temp[8];
    #$Eat[$count]    = $temp[9];
    for my $im (0..$#methods) { $Eat[$count][$im] = $temp[$im+9]; }
  }
  close LIST;

  undef %educts;
  undef %products;

#  Educts
  for($i=0;$i<=$count;$i++){
    for($j=$i+1;$j<=$count;$j++){
      undef %educts;
      $educts{$AT[$i][1]} += $nAT[$i][1];
      $educts{$AT[$i][2]} += $nAT[$i][2];
      $educts{$AT[$i][3]} += $nAT[$i][3];
      $educts{$AT[$i][4]} += $nAT[$i][4];
      $educts{$AT[$j][1]} += $nAT[$j][1];
      $educts{$AT[$j][2]} += $nAT[$j][2];
      $educts{$AT[$j][3]} += $nAT[$j][3];
      $educts{$AT[$j][4]} += $nAT[$j][4];
      $educts{'xxxx'}       = 0;
    # Products
      for($k=0;$k<=$count;$k++){
        for($l=$k+1;$l<=$count;$l++){
          undef %products;
          $products{$AT[$k][1]} += $nAT[$k][1];
          $products{$AT[$k][2]} += $nAT[$k][2];
          $products{$AT[$k][3]} += $nAT[$k][3];
          $products{$AT[$k][4]} += $nAT[$k][4];
          $products{$AT[$l][1]} += $nAT[$l][1];
          $products{$AT[$l][2]} += $nAT[$l][2];
          $products{$AT[$l][3]} += $nAT[$l][3];
          $products{$AT[$l][4]} += $nAT[$l][4];
          $products{'xxxx'}       = 0;          

          $match = 1;

          for(keys %educts){
            unless ( exists $products{$_}){
              $match=0;
              next;
            }
            if($educts{$_}!=$products{$_}){
              $match=0;
            }
          }
          for(keys %products){
            unless ( exists $educts{$_}){
              $match=0;
              next;
            }
            if($educts{$_}!=$products{$_}){
              $match=0;
            }
          }
          if($match==1){
            my @E_r;
            unless(($mol[$i] eq $mol[$k]) or 
                   ($mol[$j] eq $mol[$l]) or
                   ($mol[$i] eq $mol[$l]) or
                   ($mol[$j] eq $mol[$k]) 
                                        ){
              for($ire=0;$ire<=$rcount;$ire++){
                if(($mol[$i] eq $reactions[$ire][3]) and
                   ($mol[$j] eq $reactions[$ire][4]) and
                   ($mol[$k] eq $reactions[$ire][1]) and
                   ($mol[$l] eq $reactions[$ire][2])){
                  $match=0; 
                }
              }
              if($match==1){
                $rcount++;
                $reactions[$rcount][1] = $mol[$i];
                $reactions[$rcount][2] = $mol[$j];
                $reactions[$rcount][3] = $mol[$k];
                $reactions[$rcount][4] = $mol[$l];
                for my $im (0..$#methods) {
                  $E_r[$im] = ($Eat[$i][$im]+$Eat[$j][$im]) - ($Eat[$k][$im]+$Eat[$l][$im]); 

                }
              # bondtypes
                if($dobonds == 1){
                  $bonddiff = 0;
                  for($ia=0;$ia<18;$ia++){
                    for($ja=$ia;$ja<18;$ja++){
                      $bonddiff += abs(($bondmatrix{$mol[$i]}{$elements[$ia]}{$elements[$ja]}+
                                        $bondmatrix{$mol[$j]}{$elements[$ia]}{$elements[$ja]})-  
                                       ($bondmatrix{$mol[$k]}{$elements[$ia]}{$elements[$ja]}
                                       +$bondmatrix{$mol[$l]}{$elements[$ia]}{$elements[$ja]}));
                    }
                  } 
                  #original
                  #print "$rcount: $mol[$i] ($i) + $mol[$j] ($j) -> $mol[$k] ($k) + $mol[$l] ($l) = $E_r kcal mol-1 $bonddiff \n";
                }else{
                  #original
                  #print "$rcount: $mol[$i] ($i) + $mol[$j] ($j) -> $mol[$k] ($k) + $mol[$l] ($l) $E_r kcal mol-1 \n";
                  printf("%-6d%12s%12s%12s%12s",$rcount, $mol[$i], $mol[$j], $mol[$k], $mol[$l]);
                  for my $im (0..$#methods) { printf("%12.2f", $E_r[$im]); }
                  print "\n";
                }
              }
            }
          }
        }
      }
    } 
  }

