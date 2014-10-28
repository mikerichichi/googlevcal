#!/usr/bin/perl

use ATTIC;

use Time::Local;
use Switch;

$user=$ARGV[1];

chomp $user;

$coursegrps = $ldap->search(base=>"$user",scope=>base, filter=>"objectclass=*");

$coursegrps->code && warn "add sched: ", $coursegrps->error;

$courseuser=$coursegrps->pop_entry;


@courses = $courseuser->get_value('groupMembership');

print "BEGIN:VCALENDAR\nVERSION:2.0\n";
print "PRODID:vCalDump\n";

@exdate=(20141013,20141014,20141126,20141127,20141128,20141209,20141210,20141211,20141212,20141213,20141214,20141215,20141216,20141217);


foreach $course (@courses) {

        if ($course=~/$current_term/) {
        $all_objects=$ldap->search (base=>"$course",scope=>base, filter=>"objectclass=drewCourseSection");


        foreach $entry ($all_objects->all_entries) {
                print "BEGIN:VEVENT\n";
                $moddn=$entry->dn;
                print "UID:$moddn\n";
                $cn=$entry->get_value('cn');
                $location=$entry->get_value('drewCourseSectionMeetingLocation');
                $meetingtime=$entry->get_value('drewCourseSectionMeetingTime');
                $description=$entry->get_value('description');
                ($days, $times) = split(' ',$meetingtime);
                $days=~s/M/MO,/;
                $days=~s/T/TU,/;
                $days=~s/W/WE,/;
                $days=~s/R/TH,/;
                $days=~s/F/FR,/;
                $days=substr($days,0,-1);
                ($start, $end) = split('-',$times);
                $term_start=$entry->get_value('drewCourseSectionPOTStartDate');
                $course_start=substr($term_start,0,8);
                $course_start_month=substr($course_start,4,2);
                $course_start_day=substr($course_start,6,2);
                $course_start_year=substr($course_start,0,4);
                $course_start_secs=timelocal(0,0,0,$course_start_day,$course_start_month,$course_start_year);
                switch (substr($days,0,2)) {
                        case "TU" { $course_start_secs+=86400; }
                        case "WE" { $course_start_secs+=(86400*2); }
                        case "TH" { $course_start_secs+=(86400*3); }
                        case "FR" { $course_start_secs+=(86400*4); }
                }
 ($sec,$min,$hour,$course_start_day,$course_start_month,$course_start_year,$wday,$yday,$isdst) =localtime($course_start_secs);
                $course_start_year += 1900;
                $course_start_month = sprintf("%02d", $course_start_month);
                $course_start_day = sprintf("%02d", $course_start_day);
                $term_end=$entry->get_value('drewCourseSectionPOTEndDate');
                $course_start=$course_start_year.$course_start_month.$course_start_day."T".$start."00";
                $course_end=$course_start_year.$course_start_month.$course_start_day."T".$end."00";
                $exdatestring="";
                foreach $ex  (@exdate) {
                        $exdatestring=$exdatestring."$ex"."T".$start."00".",";
                }
                $exdatestring=substr($exdatestring,0,-1);
                if ($meetingtime ne "") {
                print "DTSTART:$course_start\nDTEND:$course_end\n";
                print "RRULE:FREQ=WEEKLY;UNTIL=$term_end;BYDAY=$days\n";
                print "EXDATE:$exdatestring\n";
                print "LOCATION:$location\n";
                print "DESCRIPTION:$description\n";
                print "SUMMARY:$cn\n";
                print "END:VEVENT\n\n";
        }
}}
}
print"END:VCALENDAR\n";
