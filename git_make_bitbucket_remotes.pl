#!/usr/bin/perl

use Cwd;

my $dir = getcwd;

opendir(CWD, $dir);
my @git_repo_dirs = grep { -d $dir . '/' . $_ . '/.git' } readdir(CWD);
closedir(CWD);

print "The following directories do NOT have a remote setup:\n\n";

foreach my $git_dir (@git_repo_dirs) {
	
	# don't care about any temp dirs
	# in my case it was project-build-tmp and project-tests-tmp
	# going into a project-main folder
	if ($git_dir =~ /tmp$/) {
		next;
	}
	
	chdir($git_dir);
	
	my $remotes_output = `git remote`;
	
	if ($remotes_output eq '') {
		print $git_dir . "\n";
	}
	
	chdir('..');
}