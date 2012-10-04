#!/usr/bin/perl

use Cwd;

use JSON;

use Data::Dumper;

my $dir = '.';

my @git_repo_dirs = &get_git_repo_dirs($dir);

my @git_no_remote_dirs = &get_no_remote_dirs($dir, \@git_repo_dirs);

# either set BB_USERNAME and BB_PASSWORD as part of the environment or set them here...
if (!exists($ENV{'BB_USERNAME'})) {
	print "Using SCRIPT variables rather than pre-set ENV variables...\n\n";
	$ENV{'BB_USERNAME'} = 'put_your_bitbucket_username_here';
	$ENV{'BB_PASSWORD'} = 'put_your_bitbucket_password_here';
}

my @remote_repos = &get_remote_repo_list();

foreach my $no_remote_dir (@git_no_remote_dirs) {
	if (!&in_array($no_remote_dir, \@remote_repos)) {
		&handle_bitbucket_stuff($dir, $no_remote_dir);
	} else {
		# you might actually want to see this...if it ever happen to you
		# in this case, there's a local repository with no remote setup
		# and a remote repository with the same 'slug'...
		print "---------------------------------------------------------\n";
		print $no_remote_dir . " IS ALREADY on bitbucket\n";
		print "---------------------------------------------------------\n";
		sleep(10);
	}
}

sub get_git_repo_dirs {
	my ($p_dir) = @_;
	
	
	opendir(CWD, $p_dir);
	my @r = grep { -d $p_dir . '/' . $_ . '/.git' } readdir(CWD);
	closedir(CWD);
	
	return @r;
}

sub get_no_remote_dirs {
	my ($p_baseDir, $p_dirs) = @_;
	
	my $main_dir = getcwd;
	
	my @r = ();
	
	foreach my $git_dir (@$p_dirs) {
		
		# don't care about any temp dirs
		# in my case it was project-build-tmp and project-tests-tmp
		# going into a project-main folder
		if ($git_dir =~ /tmp$/) {
			next;
		}
		
		chdir($p_baseDir . '/' . $git_dir);
		
		my $remotes_output = `git remote`;
		
		if ($remotes_output eq '') {
			push(@r, $git_dir);
		}
		
		chdir($main_dir);
	}
	
	return @r;
	
}

sub get_remote_repo_list {
	my $repo_list_cmd = 'curl -k -s -u ' . $ENV{'BB_USERNAME'} . ':' . $ENV{'BB_PASSWORD'} . ' https://api.bitbucket.org/1.0/users/' . $ENV{'BB_USERNAME'};
	
	my $response = `$repo_list_cmd`;

	my $json = new JSON();

	my $data = $json->decode($response);
	
	my @r = ();
	
	if (!exists($data->{'repositories'})) {
		die "Invalid response received from Bitbucket.  Format may have changed!";		
	}
	
	my $repos = $data->{'repositories'};
	foreach my $repo (@$repos) {
		if ($repo->{'scm'} eq 'git') {
			push(@r, $repo->{'slug'});
		}
		
	}	
	
	return @r;
}

sub in_array {
	my ($needle, $haystack) = @_;
	
	return grep { $_ eq $needle } @$haystack;
}

sub handle_bitbucket_stuff {
	my ($p_baseDir, $p_repoName) = @_;
	
	my $current_dir = getcwd;
	
	print "Handling: " . $p_repoName . "\n";
	
	print "\tMaking Repo on bitbucket...";
	
	chdir($p_baseDir . '/' . $p_repoName);
	
	my $repo_slug = &make_bitbucket_repository($p_repoName);
	
	print "Done!\n";
	
	print "\tAdding remote branch to local repo...";
	
	my $add_remote_cmd = 'git remote add origin https://' . $ENV{'BB_USERNAME'} . ':' . $ENV{'BB_PASSWORD'} . '@bitbucket.org/' . $ENV{'BB_USERNAME'} . '/' . $repo_slug . '.git';
	
	my $output = `$add_remote_cmd`;
	
	if ($? != 0) {
		die "Could not add remote...check STDERR...";
	}
	
	print "Done!\n";
	
	print "\tPushing data up...\n";
	
	my $output2 = `git push origin master`;
	
	if ($? != 0) {
		die "Could not push to bitbucket...check STDERR...";
	}
	
	print "\n\tDone with " . $p_repoName . "\n\n";
	
	chdir($current_dir);
	
	# if you want to do this one repo at a time...
	# exit;
	
}

sub make_bitbucket_repository {
	my ($repo_name) = @_;
	my $make_repo_cmd = 'curl -k -s -u ' . $ENV{'BB_USERNAME'} . ':' . $ENV{'BB_PASSWORD'} . ' -F scm=git -F is_private=true -F name=' . $repo_name . ' https://api.bitbucket.org/1.0/repositories';
	
	my $response = `$make_repo_cmd`;
	
	if ($? != 0) {
		die "Got an invalid response from bitbucket!";
	}
	
	my $json = new JSON();
	
	my $data = $json->decode($response);
	
	return $data->{'slug'};
}