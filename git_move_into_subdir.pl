#!/usr/bin/perl

if (!&is_inside_git_dir) {
	print "You need to call this from inside a git repository.\n\n";
	&usage;
}

print "Checking for un-committed changes...";

&make_sure_up_to_date;

print "No un-committed changes...ready to proceed!\n\n";

my $dir = $ARGV[0];

if ($dir eq '') {
	&usage;
}

print "Moving all files into: " . $dir . "\n";

if (!-d $dir) {
	$worked = mkdir($dir);
	if (!$worked) {
		print STDERR "Unable to make directory: " . $dir . ": $!\n\n";
		&usage;
	}
}

opendir(DIR, ".");

my @do_not_move = ('.', '..', '.git', $dir);

while (my $file = readdir(DIR)) {
	if (grep { $_ eq $file } @do_not_move) {
		next;
	}
	
	# print "Moving " . $file . " into " . $dir . "\n";
	
	system('git mv -v ' . $file . ' ' . $dir);
	
	if ($? != 0) {
		print "Error moving " . $file . " into " . $dir . "\n";
		exit;
	}
}

system('git add -v .');
 
 

if ($? != 0) {
	print "Error adding files to staged repository!\n";
	exit;
}

system('git commit -m "Moved all files into: ' . $dir . '"');


sub usage {
	print "Usage: " . $0 . " <subdir_to_use>\n\n";
	print "Move all files inside this directory to <subdir_to_use>\n";
	exit;
}

sub is_inside_git_dir {
	my $output = `git rev-parse --is-inside-work-tree 2>&1`;
	
	if ($output =~ /true/) {
		return 1;
	} else {
		return 0;
	}
}

sub make_sure_up_to_date {
	my $output = `git status -s`;
	
	if ($output ne '') {
		print "You have un-committed changes.  Commit or reset those changes before running this tool.\n\n";
		print $output . "\n\n";
		&usage;
	}
	
	system('git --no-pager diff --exit-code --quiet');
	
	if ($? != 0) {
		print "You have un-committed changes.  Commit or reset those changes before running this tool.\n\n";
		&usage;
	}
	
	system('git --no-pager diff --exit-code --quiet --cached');
	
	if ($? != 0) {
		print "You have un-committed changes that are staged.  Commit or reset those changes before running this tool.\n\n";
		&usage;
	}

	# need to fix for repos that don't have an origin...
#	my $output = `git rev-list origin/\`git rev-parse --abbrev-ref HEAD\`..HEAD -n 1`;
	
#	if ($output ne '') {
#		print "NOTE: You have changes not pushed to upstream yet...continuing anyway...\n\n";
#		print $output . "\n\n";
#	}
}