# ---------------------------------------------------------------------------------
# CouchDB
# https://docs.couchdb.org/en/stable/
#
# @author AlexandrinK <aks@cforge.org>
# ---------------------------------------------------------------------------------
package CouchDB::CouchManager;
use LWP::UserAgent;
use Encode;
use JSON -convert_blessed_universally;

#
#  host => '', port => 0, username=>'', password=>'', timeout=>0
#
sub new {
	my $class = shift;
    my %opts = @_;
    my %t = (
    	_json 	 => JSON->new(),
		_ua   	 => LWP::UserAgent->new(),
		_url	 => undef,
		host	 => 'localhost',
		port	 => 5984,
		timeout  => 0,
		realm	 => 'administrator',
		username => undef,
		password => undef
    );
    my $self = {%t, %opts};
    #
    $self->{_url} = "http://".$self->{host}.':'.$self->{port};
    $self->{_ua}->timeout($self->{timeout}) if($self->{timeout});
    #
    return bless($self, $class);
}

sub get_url {
    my $self = shift;    
    return $self->{_url};
}

sub json_serialize { 
    my ($self, $obj) = @_;
    my $json = $self->{_json};    
    return $json->encode($obj);
}

sub json_deserialize { 
    my ($self, $jtext) = @_;
    my $json = $self->{_json};    
    return $json->decode($jtext);
}

# show all dbs
#
# return	: array 
# exceptons	: CouchDB::CouchException
sub list_dbs {
	my $self = shift;
	my $url = $self->{_url}.'/_all_dbs'; 	
	my $o = $self->_send('GET', $url);
	if($self->_is_error($o)) {
		$self->_throw_execption($o);		
	} 	
	return $o;
}

# connect to db
#
# arg0		: db name
# return	: CouchDB::CouchDB
# exceptons	: CouchDB::CouchException
sub open_db {
	my ($self, $db_name) = @_;
	my $url = $self->{_url}.'/'.$db_name;	
	unless($self->exists_db($db_name)) {
		die CouchDB::CouchException->new('not_found', 'Document does not exist');
	}
	return CouchDB::CouchDB->new($self, $url, $db_name);
}

# db exists
#
# arg0		: db name
# return	: true/false
# exceptons	: -- 
sub exists_db {
	my ($self, $db_name) = @_;	
	my $url = $self->{_url}.'/'.$db_name;
 	my $o = $self->_send('HEAD', $url);
 	if(ref($o) eq 'HASH') {
 		return 1 if($o->{'error'} eq '200');
 	}
 	return 0; 
}

# create a new db
# reqires admin role (don't forget to uncomment property in local.ini: WWW-Authenticate = Basic realm="administrator")
#
# arg0		: db name
# return	: true/false
# exceptons	: CouchDB::CouchException
sub create_db {
	my ($self, $db_name) = @_;
	my $url = $self->{_url}.'/'.$db_name; 		
	my $o = $self->_send('PUT', $url);
	if($self->_is_error($o)) {
		$self->_throw_execption($o);
	}
	if(ref($o) eq 'HASH') {
		return 1 if($o->{ok} == JSON::true);
	}
	return 0;
}

# delete db
#
# arg0		: db name
# return	: true/false
# exceptons	: CouchDB::CouchException
sub delete_db {
	my ($self, $db_name) = @_;
	my $url = $self->{_url}.'/'.$db_name;
 	my $o = $self->_send('DELETE', $url);
	if($self->_is_error($o)) {
		$self->_throw_execption($o);
	}
	if(ref($o) eq 'HASH') {
		return 1 if($o->{ok} == JSON::true);
	}
	return 0;
}

# get db info
#
# arg0		: db name
# return	: db info object
# exceptons	: CouchDB::CouchException
sub get_db_info {
	my ($self, $db_name) = @_;
	my $url = $self->{_url}.'/'.$db_name;
 	my $o = $self->_send('GET', $url); 	
 	if($self->_is_error($o)) {
 		$self->_throw_execption($o);
 	} 	
	return $o;
}

# ----------------------------------------------------------------------------------------------------------------------------
# helper methods
sub _send {
	my ($self, $method, $url, $data) = @_;
	my $json = $self->{_json};
	my $ua = $self->{_ua};	
	#
	if(defined($self->{username}) && defined($self->{password})) {
        $ua->credentials($self->{host}.':'.$self->{port}, $self->{realm}, $self->{username}, $self->{password});
    }
    my $req = HTTP::Request->new($method, $url);
    $req->header('Content-Type' => 'application/json; charset=UTF-8');
    if(defined($data)) {
    	$req->content(Encode::encode('utf8', $data));
    }
    my $tt = $ua->request($req);
    my $body = $tt->decoded_content({default_charset => 'utf8'});    
    my $result = undef;
    eval { $result = $json->decode($body); };
    if ($@) {
    	return return {error => $tt->code, reason => $tt->status_line};
    }
    return $result;
}
sub _get_req_params {
	my $self = shift;
	my $amap = shift;	
	#
    my @alst = map {"$_=$amap->{$_}"} keys %{$amap};
    return join('&', @alst);    
}
sub _is_error {
	my ($self, $obj) = @_;	
	return 1 if((ref($obj) eq 'HASH') && defined($obj->{error}));
	return undef;
}

sub _throw_execption {
	my ($self, $err) = @_;
	if((ref($err) eq 'HASH') && defined($err->{error})) {
		die CouchDB::CouchException->new($err->{error}, $err->{reason});
	}
	return undef;
}

# ----------------------------------------------------------------------------------------------------------------------------
# helper objects
# ----------------------------------------------------------------------------------------------------------------------------
package CouchDB::CouchDB;
use overload '""' => 'stringify';

sub new($$;$) {
    my ($class, $manager, $url, $name) = @_;
    my $self = {
    	manager => $manager,
    	db_name	=> $name,
    	url 	=> $url    	
    };   
    return bless($self, $class);
}

sub get_url {
	my $self = shift;
	return $self->{url};
}

sub get_db_name {
	my $self = shift;
	return $self->{db_name};
}

sub get_manager {
	my $self = shift;
	return $self->{manager};
}

sub stringify {
	my $self = shift;
    return 'CouchDB: ' .$self->{url};
}

# document exists
#
# arg0		: document id
# return	: true/false
# exceptons	: --
sub exists_doc {
	my ($self, $doc_id) = @_;	
	my $mgr = $self->{manager};
	#
	my $url = $self->{url}.'/'.$doc_id;
 	my $o = $mgr->_send('HEAD', $url);
 	if(ref($o) eq 'HASH') {
 		return 1 if($o->{'error'} eq '200');
 	}
 	return 0;
}

# create a new document
#
# arg0		: document id
# arg1		: document obj
# return	: a new docuemnt
# exceptons	: CouchDB::CouchException
sub add_doc {
	my ($self, $doc_id, $doc) = @_;
	my $mgr = $self->{manager};
	#
	$doc->{_id} = $doc_id;
	#
	my $json = $mgr->json_serialize($doc); 
	my $url = $self->{url}.'/'.$doc_id;	
	my $o = $mgr->_send('PUT', $url, $json);
 	if($mgr->_is_error($o)) {
 		$mgr->_throw_execption($o); 		
 	}
 	return $self->get_doc($doc_id);
}

# update the document
#
# arg0		: document id
# arg1		: document obj
# return	: updated docuemnt
# exceptons	: CouchDB::CouchException
sub update_doc {
	my ($self, $doc_id, $doc) = @_;
	my $mgr = $self->{manager};
	#
	my $json = $mgr->json_serialize($doc); 
	my $url = $self->{url}.'/'.$doc_id;	
	my $o = $mgr->_send('PUT', $url, $json);
 	if($mgr->_is_error($o)) {
 		$mgr->_throw_execption($o); 		
 	}
 	return $self->get_doc($doc_id);
}

# delete the document
#
# arg0		: document id
# arg1		: document revision
# return	: true/false
# exceptons	: CouchDB::CouchException
sub delete_doc {
	my ($self, $doc_id, $doc_rev) = @_;
	my $mgr = $self->{manager};
	#
	my $url = $self->{url}.'/'.$doc_id.'?rev='.$doc_rev;	
	my $o = $mgr->_send('DELETE', $url);
 	if($mgr->_is_error($o)) {
 		$mgr->_throw_execption($o); 		
 	}
	if(ref($o) eq 'HASH') {
		return 1 if($o->{ok} == JSON::true);
	} 	
 	return 0;
}

# get document by id
#
# arg0		: document id
# return	: the document or undef if doesn't exist
# exceptons	: CouchDB::CouchException
sub get_doc {
	my ($self, $doc_id) = @_;
	my $mgr = $self->{manager};
	#
	my $url = $self->{url}.'/'.$doc_id;	
	my $o = $mgr->_send('GET', $url);
 	if($mgr->_is_error($o)) {
 		return undef if($o->{'error'} eq 'not_found');
 		$mgr->_throw_execption($o);
 	}
	return $o;
}

# find document (mango query)
# https://docs.couchdb.org/en/stable/api/database/find.html
#
# arg0		: query 
# return	: array of ducuments
# exceptons	: CouchDB::CouchException
sub find_doc {
	my ($self, $query) = @_;
	my $mgr = $self->{manager};
	#
	my $json = $mgr->json_serialize($query);
	my $url = $self->{url}.'/_find';	
	my $o = $mgr->_send('POST', $url, $json);	
	if($mgr->_is_error($o)) {
 		$mgr->_throw_execption($o);
 	}
	return $o;
}

# find document (view)
#
# arg0		: view name
# arg1+		: view args
# return	: array of ducuments
# exceptons	: CouchDB::CouchException
sub view_doc {
	my $self = shift;
	my $view = shift;
	my %args = @_;
	my $mgr = $self->{manager};
	#
	my $prms = $mgr->_get_req_params(\%args);
	my $url = $self->{url}.'/_view/'.$view.'?'.$prms;	
	my $o = $mgr->_send('GET', $url);
	if($mgr->_is_error($o)) {
		$mgr->_throw_execption($o);		
	}	
	return $o;	
}

# list all documents
#
# arg*		: params (for example: include_docs => 'true')
# return	: array of documents
# exceptons	: CouchDB::CouchException
sub list_docs {
	my $self = shift;
	my %args = @_;
	my $mgr = $self->{manager};
	#
	my $prms = $mgr->_get_req_params(\%args);
	my $url = $self->{url}.'/_all_docs?'.$prms;	
	my $o = $mgr->_send('GET', $url);
	if($mgr->_is_error($o)) {
		$mgr->_throw_execption($o);		
	}	
	return $o;
}

# ----------------------------------------------------------------------------------------------------------------------------
package CouchDB::CouchException;
use overload '""' => 'stringify';

sub new($$;$) {
    my ($class, $err, $reason) = @_;
    my $self = {
    	error 	=> $err,
    	reason => $reason
    };   
    return bless($self, $class);
}

sub get_error {
	my $self = shift;
	return $self->{error}; 	
}

sub get_reason {
	my $self = shift;
	return $self->{reason}; 	
}

sub stringify {
	my $self = shift;
    return 'CouchException: ' .$self->{error}.' ('.$self->{reason}.')';
}

# ----------------------------------------------------------------------------------------------------------------------------
# END
1;