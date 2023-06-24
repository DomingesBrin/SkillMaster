#!/usr/bin/perl

# A Skill Development Service for Businesses

# Open database connection 
use DBI;
my $dbh = DBI->connect("DBI:mysql:database-name:localhost","username","password",
	{RaiseError => 1});

# Declare function for finding user's skill level 
sub get_user_skill_level {
	my ($username) = @_;
	my $query = $dbh->prepare("SELECT skill_level FROM user_skills WHERE username = ?");
	$query->execute($username);
	my $skill_level = $query->fetchrow_array();
	return $skill_level // 0;
}

# Access course data from database 
my $course_query = $dbh->prepare("SELECT * FROM courses WHERE recommended_level <= ?");

# Declare function for finding course recommendations 
sub get_courses_recommendations {
	my ($skill_level) = @_;
	$course_query->execute($skill_level);
	my @courses;
	while (my $row = $course_query->fetchrow_hashref()) {
		push(@courses, $row);
	}
	return \@courses;
}

# Declare function for registering user for course
sub register_user_for_course {
	my ($username, $course_id) = @_;
	my $register_query = $dbh->prepare("INSERT INTO user_courses (username, course_id) 
										VALUES (?, ?)");
	$register_query->execute($username, $course_id);
}

# Declare function for retrieving courses user has registered for
sub get_user_registered_courses {
	my ($username) = @_;
	my $registered_query = $dbh->prepare("SELECT course_id FROM user_courses WHERE username = ?");
	$registered_query->execute($username);
	my @registered;
	while (my $row = $registered_query->fetchrow_arrayref()) {
		push(@registered, $row->[0]);
	}
	return \@registered;
}

# Declare function to complete course
sub complete_course {
	my ($username, $course_id) = @_;
	my $complete_query = $dbh->prepare("UPDATE user_courses SET completed = 1 WHERE username = ? AND course_id = ?");
	$complete_query->execute($username, $course_id);
}

# Declare function for updating user's skill level
sub update_skill_level {
	my ($username, $skill_level) = @_;
	my $update_query = $dbh->prepare("UPDATE user_skills SET skill_level = ? WHERE username = ?");
	$update_query->execute($skill_level, $username);
}

# Declare function for calculating user's new skill level 
sub calculate_skill_level {
	my ($username) = @_;
	my $current_level = get_user_skill_level($username);
	my $completed_courses = get_user_registered_courses($username);
	foreach my $course_id (@{$completed_courses}) {
		my $course_level = get_course_level($course_id);
		$current_level += $course_level;
	}
	return $current_level;
}

# Declare function for getting course level 
sub get_course_level {
	my ($course_id) = @_;
	my $course_query = $dbh->prepare("SELECT skill_level FROM courses WHERE id = ?");
	$course_query->execute($course_id);
	my $course_level = $course_query->fetchrow_array();
	return $course_level;
}

# Declare function for providing course management services 
sub manage_courses {
	my ($username, $action) = @_;
	if ($action eq 'register') {
		my $skill_level = get_user_skill_level($username);
		my $courses = get_courses_recommendations($skill_level);
		foreach my $course (@{$courses}) {
			register_user_for_course($username, $course->{id});
		}
	} elsif ($action eq 'complete') {
		my $completed_courses = get_user_registered_courses($username);
		foreach my $course_id (@{$completed_courses}) {
			complete_course($username, $course_id);
		}
		my $new_skill_level = calculate_skill_level($username);
		update_skill_level($username, $new_skill_level);
	}
}

# Close database connection 
$dbh->disconnect();