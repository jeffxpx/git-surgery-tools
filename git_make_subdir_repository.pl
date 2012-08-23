#!/usr/bin/perl

my $original_dir = $ARGV[0];
my $new_dir = $ARGV[1];
my $sub_dir = $ARGV[2];

&check_constraints;

print "Everything looks valid...\n\n";
print "Extracting: " . $sub_dir . "\nFrom: " . $original_dir . "\nInto a new repository named: " . $new_dir . "\n\n";

print "Step 1: Cloning repository...";
&wrapped_command('git clone ' . $original_dir . ' ' . $new_dir);

if (-e $new_dir . '/.git') {
	print "Done!\n";
}

print "Step 2: Track all important branches...";

chdir($new_dir);

my $branch_list_output = &wrapped_command('git branch -a', 'FAILED...COULD NOT GET BRANCH LIST!');

&track_remote_branches_and_remove_remotes($branch_list_output);

print "Done!\n";

print "Step 3: Filter repository on subdirectory...this may take a while...";

&wrapped_command('git filter-branch --tag-name-filter cat --prune-empty --subdirectory-filter ' . $sub_dir . ' -- --all');

print "Done!\n";

print "Step 4: Cleanup and GC...";

&wrapped_command('git reset --hard', 'FAILED TRYING TO DO HARD RESET!');
&wrapped_command('git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d', 'FAILED ON FOR-EACH-REF!');
&wrapped_command('git reflog expire --expire=now --all', 'FAILED EXPIRING OLD REFLOGS!');
&wrapped_command('git gc --aggressive --prune=now', 'FAILED GC-ING!');

print "Done!\n\n";

print "Congratulations!  " . $new_dir . " is now a git repository that only contains the contents of: " . $sub_dir . "!\n\n";
print $original_dir . " was not harmed in the process!\n";

sub track_remote_branches_and_remove_remotes {
	my ($branch_list_str) = @_;
	
	my @branches = split(/\n/, $branch_list_str);
	
	my @branches_made = ();
	my @local_branches = ();
	
	my @remotes = ();
	
	foreach my $branch (@branches) {
		my $branch_name = substr($branch, 2);
		if ($branch_name !~ /^remotes\//) {
			# print $branch_name . " is a local branch...\n";
			push(@local_branches, $branch_name);
		} else {
			my $remote_branch_name = $branch_name;
			
			$remote_branch_name =~ s/^remotes\///g;
			
			my $clean_remote_branch_name = $remote_branch_name;
			$clean_remote_branch_name =~ s/ .*//g;
			
			my ($remote, $actual_branch_name) = split(/\//, $clean_remote_branch_name, 2);
			
			unless (grep { $_ eq $remote } @remotes) {
				push(@remotes, $remote);
			}
			
			if ($actual_branch_name eq 'HEAD') {
				# don't care about HEAD
				next;
			}
			
			# print $actual_branch_name . " is a remote branch...\n";
			
			if (grep { $_ eq $actual_branch_name } @local_branches) {
				# print "We already have a local version of " . $actual_branch_name . "\n";
				next;
			}
			
			# print "Making a local version of " . $actual_branch_name . "...";
			my $output = &wrapped_command('git branch -t ' . $actual_branch_name . ' ' . $clean_remote_branch_name, 'FAILED!');
			# print "Done!\n";
			
			push(@branches_made, $actual_branch_name);
		}
	}
	
	# print "Made these local branches: " . join(", ", @branches_made) . "\n\n";
	# print "Removing remote references for safety...\n";
	
	foreach my $remote (@remotes) {
		# print "Removing reference to remote: " . $remote . "...";
		&wrapped_command('git remote rm ' . $remote, 'FAILED!');
		# print "Done!\n";
	}
}




sub wrapped_command {
	local ($command, $error_message) = @_;
	
	if ($error_message eq '') {
		$error_message = 'FAILED!';
	}
	
	local $output = `$command`;
	
	if ($? != 0) {
		print $error_message . "\n\n";
		print $output;
		
		exit;
	}
	
	return $output;
}

sub check_constraints {

	if ($original_dir eq '' || $new_dir eq '' || $sub_dir eq '') {
		&usage;
	}

	if (!-e $original_dir . '/.git') {
		print $original_dir . " is not a Git repository!\n\n";
		&usage;
	}

	if (-e $new_dir) {
		print $new_dir . " SHOULD NOT EXIST!\n";
		&usage;
	}

	if (!-e $original_dir . '/' . $sub_dir) {
		print $sub_dir . " is not a valid subdirectory of " . $original_dir . "!\n\n";
		&usage;
	}
}

sub usage {
	print "Usage: " . $0 . " <main_repo> <new_repo> <subdirectory_to_filter>\n";
	exit;
}