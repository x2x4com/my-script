# phpMyAdmin SQL Dump
# version 2.5.3
# http://www.phpmyadmin.net
#
# Host: localhost
# Generation Time: Jun 04, 2004 at 11:26 AM
# Server version: 3.23.55
# PHP Version: 4.3.0
# 
# Database : `vpopmail`
# 

# --------------------------------------------------------

#
# Table structure for table `address`
#

use vpopmail;


CREATE TABLE `address` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `pw_id` int(5) NOT NULL default '0',
  `name` varchar(64) NOT NULL default '',
  `email` varchar(128) NOT NULL default '',
  UNIQUE KEY `id` (`id`),
  KEY `pw_id` (`pw_id`)
) TYPE=MyISAM PACK_KEYS=1 ;

# --------------------------------------------------------

#
# Table structure for table `admin`
#

CREATE TABLE `admin` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `site_id` int(10) unsigned NOT NULL default '0',
  `domain` varchar(128) NOT NULL default '',
  `quota` smallint(5) unsigned NOT NULL default '0',
  `total` smallint(5) unsigned NOT NULL default '0',
  `createtime` timestamp(14) NOT NULL,
  `login` char(1) NOT NULL default '',
  `cur_total` smallint(5) NOT NULL default '0',
  `cur_quota` smallint(5) NOT NULL default '0',
  `gid` varchar(11) NOT NULL default '',
  `expiration_time` timestamp(14) NOT NULL,
  `flag` int(10) unsigned NOT NULL default '0',
  `maxmsg` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `domain` (`domain`)
) TYPE=MyISAM PACK_KEYS=1 ;

# --------------------------------------------------------

#
# Table structure for table `card`
#

CREATE TABLE `card` (
  `id` int(5) unsigned NOT NULL auto_increment,
  `pw_id` int(5) unsigned NOT NULL default '0',
  `LinkMan` varchar(64) NOT NULL default '',
  `CompanyName` varchar(100) NOT NULL default '',
  `Address` varchar(255) NOT NULL default '',
  `Position` varchar(32) NOT NULL default '',
  `PhoneNumber` varchar(16) NOT NULL default '',
  `Mobile` varchar(12) NOT NULL default '',
  `Email` varchar(128) NOT NULL default '',
  `Partaker` varchar(32) NOT NULL default '',
  `Memo` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=MyISAM ;

# --------------------------------------------------------

#
# Table structure for table `logs`
#

CREATE TABLE `logs` (
  `pw_id` int(5) default '0',
  `ip` varchar(15) NOT NULL default '',
  `action` varchar(15) NOT NULL default '',
  `time` datetime default NULL,
  `content` varchar(64) NOT NULL default '',
  `email` varchar(128) NOT NULL default ''
) TYPE=MyISAM;

# --------------------------------------------------------

#
# Table structure for table `message`
#

CREATE TABLE `message` (
  `id` int(5) unsigned NOT NULL auto_increment,
  `title` varchar(255) NOT NULL default '',
  `body` text NOT NULL,
  `createtime` datetime NOT NULL default '0000-00-00 00:00:00',
  `updatetime` datetime NOT NULL default '0000-00-00 00:00:00',
  `pw_domain` varchar(64) NOT NULL default '',
  UNIQUE KEY `id` (`id`)
) TYPE=MyISAM ;

# --------------------------------------------------------

#
# Table structure for table `personal`
#

CREATE TABLE `personal` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `pw_id` int(5) NOT NULL default '0',
  `truename` varchar(10) NOT NULL default '',
  `fax` varchar(20) NOT NULL default '',
  `telephone` varchar(15) NOT NULL default '',
  `sex` int(1) NOT NULL default '0',
  `year` int(4) NOT NULL default '0',
  `MONTH` int(2) NOT NULL default '0',
  `DAY` int(2) NOT NULL default '0',
  `education` varchar(4) NOT NULL default '',
  `marital` int(1) NOT NULL default '0',
  `occupation` varchar(15) NOT NULL default '',
  `companyname` varchar(30) NOT NULL default '',
  `province` varchar(6) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=MyISAM PACK_KEYS=1 ;

# --------------------------------------------------------

#
# Table structure for table `scheduler`
#

CREATE TABLE `scheduler` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `begin_time` int(11) unsigned default NULL,
  `end_time` int(11) unsigned default NULL,
  `title` varchar(255) NOT NULL default '',
  `body` varchar(255) NOT NULL default '',
  `pw_id` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=MyISAM ;

# --------------------------------------------------------

#
# Table structure for table `stow`
#

CREATE TABLE `stow` (
  `id` int(5) unsigned NOT NULL auto_increment,
  `pw_id` int(5) unsigned NOT NULL default '0',
  `Name` varchar(128) NOT NULL default '',
  `http` varchar(255) NOT NULL default 'http://',
  `memo` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=MyISAM ;

# --------------------------------------------------------

#
# Table structure for table `vpopmail`
#

ALTER TABLE `vpopmail` DROP primary key;
ALTER TABLE `vpopmail` ADD COLUMN `pw_id` int(5) unsigned NOT NULL primary key auto_increment;
ALTER TABLE `vpopmail` ADD COLUMN `createtime` timestamp(14) NOT NULL;
ALTER TABLE `vpopmail` ADD INDEX `pw_name` (`pw_name`,`pw_domain`);
INSERT INTO `admin` VALUES();
