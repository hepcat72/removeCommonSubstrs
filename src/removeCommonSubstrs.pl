#!/usr/bin/perl

#USAGE: Run with no options to get usage or with --help for basic details

use warnings;
use strict;
use CommandLineInterface;

our $VERSION = '1.003';

setScriptInfo(VERSION => $VERSION,
              CREATED => '1/5/2018',
              AUTHOR  => 'Robert William Leach',
              CONTACT => 'rleach@princeton.edu',
              COMPANY => 'Princeton University',
              LICENSE => 'Copyright 2018',
              HELP    => join('',("This takes a series of strings on the ",
				  "command line, splits them based on word ",
				  "boundaries, and removes portions of each ",
				  "string that are present in all strings.")));

my $string_array = [];
add2DArrayOption(GETOPTKEY   => 'l|list=s',
		 GETOPTVAL   => $string_array,
		 SMRY_DESC   => 'List of strings.  (Alternative to -i.)',
		 DETAIL_DESC => ('List of strings.  Each string will be ' .
				 'output after common substrings it has ' .
				 'with other strings have been removed.  ' .
		                 'Mutually exclusive with -i.  Note, ' .
				 'substrings are split based on word ' .
				 'boundaries (determined via regular ' .
				 'expression: \b).'),
                 FLAGLESS    => 1);

my $min_occ = 0;
addOption(GETOPTKEY   => 'm|min-occurrences-for-removal=i',
	  GETOPTVAL   => \$min_occ,
	  DEFAULT     => 'All',
	  SMRY_DESC   => ('Number of strings a substring must be found in, ' .
			  'in order for it to be removed.'),
	  DETAIL_DESC => ('A substring must occur in this many strings in ' .
			  'order for it to be removed.  The default ' .
			  'behavior requires the substring to be present in ' .
			  'all strings.  Must be greater than 1.'));

addInfileOption(GETOPTKEY   => 'i|infile=s',
		PRIMARY     => 1,
	        SMRY_DESC   => ('File of strings, tab and/or line-delimited.' .
				'  (Alternative to -l.)'),
		DETAIL_DESC => ('File of strings.  Strings may be tab and/' .
				'or newline delimited.  Each string will be ' .
				'output after common substrings it has with ' .
				'other strings have been removed.  ' .
				'Mutually exclusive with -l.  Note, ' .
				'substrings are split based on word ' .
				'boundaries (determined via regular ' .
				'expression: \b).'),
		FORMAT_DESC => << 'end_format'

Note, if your file contains any tab characters, each line will be treated as a list of strings from which to remove common substrings.

Commented lines (#) are skipped.

Example:

printf 'SM01__Read\tSM02__Read\tSM03__Read\tSM04__Read\tSM05__Read\tSM06__Read\tSM07__ReadSM08__Read\tSM09__Read\tSM10__Read\tSM11__Read\tSM12__Read' | removeCommonSubstrs.pl
SM01	SM02	SM03	SM04	SM05	SM06	SM07	SM08	SM09	SM10	SM11	SM12

If your file contains any tab characters at all, all output strings will be tab-delimited.  Otherwise, all output strings will be on their own line.

end_format
);

##
## Process the command line
##

processCommandLine();

#If all sub-array sizes are 1, merge into the first subarray
if(scalar(grep {scalar(@$_) == 1} @$string_array) == scalar(@$string_array))
  {$string_array = [[map {@$_} @$string_array]]}

if(getNumFileGroups() && scalar(@$string_array) &&
   scalar(grep {scalar(@$_)} @$string_array))
  {
    error("-l (with [",scalar(@$string_array),"] subarrays containing [",
	  join(',',map {scalar(@$_)} @$string_array),
	  "] values) and -i (with [",getNumFileGroups(),
	  "] values) are mutually exclusive.");
    quit(1);
  }

if(getNumFileGroups() == 0 &&
   (scalar(@$string_array) == 0 ||
    (scalar(@$string_array) == 1 && scalar(@{$string_array->[0]}) == 0)))
  {
    error("Either -l or -i is required.");
    quit(2);
  }
elsif(getNumFileGroups() == 0 &&
      scalar(@$string_array) == 1 && scalar(@{$string_array->[0]}) == 1 &&
      -e $string_array->[0]->[0])
  {
    error("Files must be supplied using -i.");
    quit(3);
  }
elsif(getNumFileGroups() == 0 &&
      scalar(@$string_array) == 1 && scalar(@{$string_array->[0]}) == 1)
  {
    error("Only 1 string supplied [$string_array->[0]->[0]].  2 or more ",
	  "strings are required.  Or, to supply a file of strings, use -i.");
    quit(4);
  }

if($min_occ < 0 || $min_occ == 1)
  {
    error("Invalid value supplied to -m [$min_occ].  Must be greater than 1.");
    quit(5);
  }

if(scalar(@$string_array) && scalar(grep {scalar(@$_)} @$string_array))
  {
    my $outfile = getOutfile();
    openOut(*OUT,$outfile) || quit(3);
    foreach my $inner_array (@$string_array)
      {print(join("\n",getShortElementStrings($inner_array,$min_occ)),"\n")}
    closeOut(*OUT);
  }
else
  {
    while(nextFileCombo())
      {
	my $infile = getInfile();
	my $outfile = getOutfile();

	openOut(*OUT,$outfile) || next;
	openIn(*IN,$infile)    || next;

	my $use_tab = 0;
	my $num     = 0;

	my $str_array = [];
	while(getLine(*IN))
	  {
	    next if(/^\s*$/ || /^\s*#/);
	    $num++;
	    push(@$str_array,[split(/\t/,$_)]);
	    if(scalar(@{$str_array->[-1]}) > 1)
	      {$use_tab = 1}
	  }
	closeIn(*IN);
	if(scalar(@$str_array) == 0 ||
	   (scalar(@$str_array) == 1 && scalar(@{$str_array->[0]}) < 2))
	  {
	    #Let's see if we can fix it by assuming delimiting spaces
	    if(scalar(@$str_array) == 1 && scalar(@{$str_array->[0]}) < 2)
	      {$str_array->[0] = [split(/(?!<\\) /,$str_array->[0]->[0])]}
	    if(scalar(@$str_array)  == 0 ||
	       (scalar(@$str_array) == 1 && scalar(@{$str_array->[0]}) == 1))
	      {
		warning("Fewer than 2 (uncommented) values were found in ",
			"file [$infile].",
			{DETAIL => ('Strings must be either tab-delimited ' .
				    'or there must be 1 on each of multiple ' .
				    'lines.' .
				    (scalar(@$str_array) == 1 &&
				     scalar(@{$str_array->[0]}) == 1 ?
				     '  Value found: [' .
				     $str_array->[0]->[0] . '].' : ''))});
		next;
	      }
	  }
	if(scalar(grep {scalar(@$_) == 1} @$str_array) == scalar(@$str_array))
	  {$str_array = [[map {@$_} @$str_array]]}
	foreach my $inner_array (@$str_array)
	  {print(join(($use_tab ? "\t" : "\n"),
		      getShortElementStrings($inner_array,$min_occ)),"\n")}
	closeOut(*OUT);
      }
  }


sub getShortStrings
  {
    my @strs          = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;
    my $smallest_size = length((sort {length($b) <=> length($a)} @strs)[0]);
    my $order = {};
    my $cnt = 0;
    foreach(@strs)
      {$order->{$_} = $cnt++}

    my $start = 0;
    foreach my $size (1..($smallest_size - 1))
      {
	my $suffix_hash = {};
	foreach my $str (@strs)
	  {$suffix_hash->{substr($str,$start,$size)}->{$str} = 1}
	if(scalar(keys(%$suffix_hash)) == scalar(@strs))
	  {return(map {substr($_,$start,$size)} @strs)}
	elsif(scalar(keys(%$suffix_hash)) > 1)
	  {return(map {getShortStrings(keys(%$_))} values(%$suffix_hash))}
	else
	  {$start = $size}
      }

    return(@strs);
  }

sub getShortStringsOld
  {
    my @strs         = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;
    my $longest_size = length((sort {length($b) <=> length($a)} @strs)[0]);

    foreach my $size (1..($longest_size - 1))
      {
	my $suffix_hash = {};
	foreach my $str (@strs)
	  {$suffix_hash->{substr($str,0,$size)} = 1}
	if(scalar(keys(%$suffix_hash)) == scalar(@strs))
	  {return(wantarray ? map {substr($_,0,$size)} @strs :
		  [map {substr($_,0,$size)} @strs])}
      }

    return(wantarray ? @strs : [@strs]);
  }

#Takes an array of strings and an optional threshold on how many times a
#substring should appear in order to remove it
sub getShortElementStrings
  {
    my @strs   = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;
    my $thresh = (scalar(@_) == 2 && ref($_[0]) eq 'ARRAY' &&
		  ref($_[1]) eq '' && $_[1] =~ /^\d+$/ && $_[1] > 1 ?
		  $_[1] : scalar(@strs));
    my @elems  = map {[grep {/./} split(/(\b|(?<=_|-)|(?=_|-))/,$_)]} @strs;

    #Find all the common elements of the string
    my $common_hash = {};
    my $i = 0; #str index
    foreach my $elem_array (@elems)
      {
	foreach my $elem (@$elem_array)
	  {$common_hash->{$elem}->{$i}++}
	$i++;
      }

    #Reconstruct the strings and remove any element that's present in all
    my @new_strs = ('') x scalar(@strs);
    $i = 0;
    foreach my $elem_array (@elems)
      {
	debug("Elements: [[",join('],[',@$elem_array),"]].");

	my $ei = 0;
	foreach my $elem (@$elem_array)
	  {
	    #If we're not at the end of the string and the next element is not
	    #included (i.e. the next element is in all of the strings)
	    my $right_included = 1;
	    if($ei != $#{$elem_array} && ($elem eq '-' || $elem eq '_'))
	      {
		my $nei = $ei + 1;
		#If the next element is only a dash/underscore, check the next
		while($nei != $#{$elem_array} &&
		      $elem_array->[$nei] =~ /^(_|-)$/)
		  {$nei++}
		if(scalar(keys(%{$common_hash->{$elem_array->[$nei]}})) >=
		   $thresh)
		  {
		    debug("Element [",$elem_array->[$nei],"] (after element ",
			  "[$elem_array->[$ei]]) is in all of the strings, ",
			  "so we're removing the dash or underscore.");
		    $right_included = 0;
		  }
	      }

	    #If we're not at the beginning of the string and the previous
	    #element is not included (i.e. the previous element is in all of
	    #the strings)
	    my $left_included = 1;
	    if($ei != 0 && ($elem eq '-' || $elem eq '_'))
	      {
		my $pei = $ei - 1;
		#If the prev element is only a dash/underscore, check the prev
		while($pei != $#{$elem_array} &&
		      $elem_array->[$pei] =~ /^(_|-)$/)
		  {$pei--}
		if(scalar(keys(%{$common_hash->{$elem_array->[$pei]}})) >=
		   $thresh)
		  {
		    debug("Element [",$elem_array->[$pei],"] (before element ",
			  "[$elem_array->[$ei]]) is in all of the strings, ",
			  "so we're removing the dash or underscore.");
		    $left_included = 0;
		  }
	      }

	    #If this element is not in all of the strings or it's a dash or
	    #underscore, append it
	    if(scalar(keys(%{$common_hash->{$elem_array->[$ei]}})) < $thresh ||
	       (($elem eq '-' || $elem eq '_') &&
		$left_included && $right_included))
	      {$new_strs[$i] .= $elem}

	    $ei++;
	  }
	$i++;
      }

    return(@new_strs);
  }
