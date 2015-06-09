use strict;
use threads;
use Thread::Queue;
    
      my $stream = new Thread::Queue;
     my $kid    = new threads(\&check_num, $stream, 2);
    
     for my $i ( 3 .. 100 ) {
         $stream->enqueue($i);
     } 
    
     $stream->enqueue(undef);
     $kid->join;
    
     sub check_num {		
         my ($upstream, $cur_prime) = @_;
		 print "function call $cur_prime \n";
         my $kid;
         my $downstream = new Thread::Queue;
         while (my $num = $upstream->dequeue) {
             next unless $num % $cur_prime;
             if ($kid) {
                $downstream->enqueue($num);
                      } else {
                print "Found prime $num\n";
                    $kid = new threads(\&check_num, $downstream, $num);
             }
         } 
         $downstream->enqueue(undef) if $kid;
         $kid->join           if $kid;
     }