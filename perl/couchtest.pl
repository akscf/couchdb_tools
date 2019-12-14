#!/usr/bin/perl

use CouchDB;
use Try::Tiny;
use Data::Dumper;

my $mgr = CouchDB::CouchManager->new(host => '127.0.0.1', username=>'test', password=>'test');
try {
	my $rc = 0;
	
	my $info = $mgr->get_db_info('testdb');
	print("DB_INFO: ".Dumper($info)."\n");

	if($mgr->exists_db('testdb1')) {
	    $rc = $mgr->delete_db('testdb1');
	    print("DELETE-RESULT: ".$rc."\n");
	} else {
	    $rc = $mgr->create_db('testdb1');
	    print("CREATE-RESULT: ".$rc."\n");
	}

	# -----------------------------------------------------------------------
	my $db = $mgr->open_db("testdb");	

	my $q = { 
	    selector => {'$and' => [ { type => 'user' }, { title => { '$regex' => "perl*" } } ]} 
	};	
	my $tt = $db->find_doc($q);
	print("FIND-RESULT: ".Dumper($tt)."\n");
	
#	my $docs = $db->list_docs(include_docs => 'true');
#	print("RESULT: ".Dumper($docs)."\n");

#	my $doc_id = '001';
#	$rc = $db->exists_doc($doc_id);
#	if($rc) {
#		my $doc = $db->get_doc($doc_id);
#		print("GET_DOC: ".Dumper($doc)."\n");
#	
#		$rc = $db->delete_doc($doc->{_id}, $doc->{_rev});
#		print("DEL_DOC: ".Dumper($rc)."\n");
#	} else {
#		my $doc = {title => "test test test", age => 1234, sid => time()};
#		$rc = $db->add_doc($doc_id, $doc);
#		print("ADD_DOC: ".Dumper($rc)."\n");
#		
#		$rc->{sid} = 'new-sid-'.time();
#		$rc = $db->update_doc($doc_id, $rc);
#		print("UPD_DOC: ".Dumper($rc)."\n");
#	}

} catch {
    warn $_;
};

