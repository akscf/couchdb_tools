Complete documentation about the CouchDB API available here: https://docs.couchdb.org/en/stable/api/index.html <br> 

Perl module:<br>

<b>CouchDB::CouchManager<b><br> 

 - list_dbs() <br>
   Get a list of available databases <br>
 
 - open_db(db_name) <br>
   'Connect' to the DB and returns  CouchDB::CouchDB <br> 
 
 - exists_db(db_name) <br>
   Returns true if the DB exists on the server;  

 - create_db(db_name) <br>
   Create a new DB and return true <br>

 - delete_db(db_name) <br>
   Delete the specified DB with documents

 - get_db_info(db_name) <br>
   Gets information about the database <br>
 
<b>CouchDB::CouchDB<b><br>

 - exists_doc(doc_id)
   Returns true if document exists in the DB <br>
   
 - add_doc(doc_id, doc_obj) <br>
   Add a new document into DB <br>
   
 - update_doc(doc_id, doc_obj) <br>
   Update the document <br>
   
 - delete_doc(doc_id, doc_revision) <br>
   Delete the document <br>
   
 - get_doc(doc_id) <br>
   Get document by id <br>
   
 - find_doc(mando_query) <br>
   Find document (/_find) <br>
   
 - view_doc(view_name, view_params...) <br>
   Find document (/_view)) <br>      
   
 - list_docs(params...)
   Get a list of all documents (/_all_docs) <br>

   
Example: <br>
```perl
#!/usr/bin/perl

use CouchDB;
use Try::Tiny;
use Data::Dumper;

my $mgr = CouchDB::CouchManager->new(host => '127.0.0.1', username=>'admin', password=>'admin');
try {
    my $dbs = $mgr->list_dbs();
    print("Available bases: ".Dumper($dbs)."\n");

    unless($mgr->exists_db('testdb2')) {
        $mgr->create_db('testdb2');

        my $db = $mgr->open_db("testdb2");
        $db->add_doc('001', {type => "post", title => "record 1", ival => 100, sid => time()});
        $db->add_doc('002', {type => "post", title => "record 2", ival => 200, sid => time()});
        $db->add_doc('003', {type => "post", title => "record 3", ival => 300, sid => time()});
        $db->add_doc('004', {type => "post", title => "record 4", ival => 400, sid => time()});

        $db->add_doc('005', {type => "user", title => "User One"});
        $db->add_doc('006', {type => "user", title => "User Two"});
        $db->add_doc('007', {type => "user", title => "Test Test"});

    }

    my $db = $mgr->open_db("testdb2");
    my $q = { selector => {'$and' => [ { type => 'user' }, { title => { '$regex' => "User*" } } ]} };
    my $tt = $db->find_doc($q);
    print("Found: ".Dumper($tt)."\n");

} catch {
    warn $_;
}
```

