---
layout: post
title: "MS-SQL Stored Procedures in Sequel: Getting the value of output variables"
categories:
- blog
---

We had the opportunity to muck around with a couple of technologies at [Tutuka][1] the last few weeks. I managed to do
some work with Ruby, specifically [Sinatra][2] and [Sequel][3]. We use MS-SQL extensively and eventually we ran into an issue where
we couldn't get the values of output variables from stored procedures. After extensive googling we found out that it's
not supported. There were a couple of clues on how it might be done (particularly this [TinyTDS Issue][4]), so after chatting
with Jeremy (the maintainer of Sequel) I decided to try and the necessary support.

It Worked!
==========

I was relatively surprised on how easy it was. As of yesterday (2014-01-02) it's now part of the Sequel version 4.6

    Add Database#call_mssql_sproc on MSSQL for calling stored procedures and handling output parameters (jrgns, jeremyevans) (#748)

How to use it
=============

You can get a good idea on how to use it from the [documentation][5], but here's a summary.

Let's say your stored procedure is defined as follows:

    CREATE PROCEDURE dbo.SequelTest(
      @Input varchar(25),
      @Output int OUTPUT
    )
    AS
      SET @Output = LEN(@Input)
      RETURN 0

If you don't care about the type or the name of the output variable, execution is as simple specifying that an argument
is an output parameter by passing the `:output` symbol as the argument value.

    DB.call_mssql_sproc(:SequelTest, {:args => ['Input String', :output]})

    > {:result => 0, :numrows => 1, :var1 => "1"}

The `result` and `numrows` element will contain the result code returned by the stored proc and the number of rows affected
respectively.

If you need to specify the type of the output variable, do so by specifying the second element of the array:

    DB.call_mssql_sproc(:SequelTest, {:args => ['Input String', [:output, 'int']]})
    
    > {:result => 0, :numrows => 1, :var1 => 1}

If you need to specify the name of the output variable, do so by specifying the third element of the array:

    DB.call_mssql_sproc(:SequelTest, {:args => ['Input String', [:output, nil, 'output']]})
    
    > {:result => 0, :numrows => 1, :output => "1"}

Enjoy!

[1]: http://www.tutuka.com
[2]: http://www.sinatrarb.com/
[3]: http://sequel.jeremyevans.net/
[4]: https://github.com/rails-sqlserver/tiny_tds/issues/24
[5]: https://github.com/jeremyevans/sequel/blob/master/doc/mssql_stored_procedures.rdoc