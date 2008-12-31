-- Copyright (c) 2000  Dustin Sallings <dustin@spy.net>
--
-- $Id: ds.sql,v 1.1 2000/11/06 07:59:26 dustin Exp $

-- This is one big fat table where we post movies and have users pick them
-- up
create table show_distribution (
	show_id varchar(32) not null,
	submitted date default now(),
	submitted_to varchar(32) not null,
	completed datetime null
);

create index show_distbyuser on show_distribution(submitted_to);

grant all on show_distribution to nobody;
