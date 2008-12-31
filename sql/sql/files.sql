-- $Id: files.sql,v 1.1 1998/11/17 10:22:39 dustin Exp $
--
-- System file comparison database

create table filetmp (
	sum      integer,
	blocks   integer,
	filename text
);

copy filetmp from '/tmp/filelist' using delimiters ' ';

create table files (
	sum      integer,
	blocks   integer,
	filename text,
	id       serial
);

insert into files(sum, blocks, filename)
    select sum, blocks, filename from filetmp;

drop table filetmp;

-- index the hell out of it
create index files_blocks on files(blocks);
create index files_sum on files using hash(sum);
create unique index files_filename on files (filename);

vacuum verbose analyze;

-- find duplicates
select sum, blocks, count(*) into table sumcount
	from files
	where blocks>0
	group by sum, blocks
;

delete from sumcount where count=1;

-- vacuum again, clear up the deletes...
vacuum verbose analyze;

create view wasted as
	select sum,blocks,count, (blocks*count) as total
		from sumcount;
