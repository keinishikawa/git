#!/bin/sh
#
# Copyright (c) 2019 Denton Liu
#

test_description='ensure rebase fast-forwards commits when possible'

. ./test-lib.sh

test_expect_success setup '
	test_commit A &&
	test_commit B &&
	test_commit C &&
	test_commit D &&
	git checkout -t -b side
'

test_rebase_same_head () {
	status_n="$1" &&
	shift &&
	what_n="$1" &&
	shift &&
	cmp_n="$1" &&
	shift &&
	status_f="$1" &&
	shift &&
	what_f="$1" &&
	shift &&
	cmp_f="$1" &&
	shift &&
	test_rebase_same_head_ $status_n $what_n $cmp_n " --apply" "$*" &&
	test_rebase_same_head_ $status_f $what_f $cmp_f " --apply --no-ff" "$*"
	test_rebase_same_head_ $status_n $what_n $cmp_n " --merge" "$*" &&
	test_rebase_same_head_ $status_f $what_f $cmp_f " --merge --no-ff" "$*"
}

test_rebase_same_head_ () {
	status="$1" &&
	shift &&
	what="$1" &&
	shift &&
	cmp="$1" &&
	shift &&
	flag="$1"
	shift &&
	test_expect_$status "git rebase$flag $* with $changes is $what with $cmp HEAD" "
		oldhead=\$(git rev-parse HEAD) &&
		test_when_finished 'git reset --hard \$oldhead' &&
		cp .git/logs/HEAD expect &&
		git rebase$flag $* >stdout &&
		if test $what = work
		then
			old=\$(wc -l <expect) &&
			test_line_count '-gt' \$old .git/logs/HEAD
		elif test $what = noop
		then
			test_cmp expect .git/logs/HEAD
		fi &&
		newhead=\$(git rev-parse HEAD) &&
		if test $cmp = same
		then
			test_cmp_rev \$oldhead \$newhead
		elif test $cmp = diff
		then
			test_cmp_rev ! \$oldhead \$newhead
		fi
	"
}

changes='no changes'
test_rebase_same_head success noop same success work same
test_rebase_same_head success noop same success work same master
test_rebase_same_head success noop same success work diff --onto B B
test_rebase_same_head success noop same success work diff --onto B... B
test_rebase_same_head success noop same success work same --onto master... master
test_rebase_same_head success noop same success work same --keep-base master
test_rebase_same_head success noop same success work same --keep-base
test_rebase_same_head success noop same success work same --no-fork-point
test_rebase_same_head success noop same success work same --keep-base --no-fork-point
test_rebase_same_head success noop same success work same --fork-point master
test_rebase_same_head success noop same success work diff --fork-point --onto B B
test_rebase_same_head success noop same success work diff --fork-point --onto B... B
test_rebase_same_head success noop same success work same --fork-point --onto master... master
test_rebase_same_head success noop same success work same --keep-base --keep-base master

test_expect_success 'add work same to side' '
	test_commit E
'

changes='our changes'
test_rebase_same_head success noop same success work same
test_rebase_same_head success noop same success work same master
test_rebase_same_head success noop same success work diff --onto B B
test_rebase_same_head success noop same success work diff --onto B... B
test_rebase_same_head success noop same success work same --onto master... master
test_rebase_same_head success noop same success work same --keep-base master
test_rebase_same_head success noop same success work same --keep-base
test_rebase_same_head success noop same success work same --no-fork-point
test_rebase_same_head success noop same success work same --keep-base --no-fork-point
test_rebase_same_head success noop same success work same --fork-point master
test_rebase_same_head success noop same success work diff --fork-point --onto B B
test_rebase_same_head success noop same success work diff --fork-point --onto B... B
test_rebase_same_head success noop same success work same --fork-point --onto master... master
test_rebase_same_head success noop same success work same --fork-point --keep-base master

test_expect_success 'add work same to upstream' '
	git checkout master &&
	test_commit F &&
	git checkout side
'

changes='our and their changes'
test_rebase_same_head success noop same success work diff --onto B B
test_rebase_same_head success noop same success work diff --onto B... B
test_rebase_same_head success noop same success work diff --onto master... master
test_rebase_same_head success noop same success work diff --keep-base master
test_rebase_same_head success noop same success work diff --keep-base
test_rebase_same_head failure work same success work diff --fork-point --onto B B
test_rebase_same_head failure work same success work diff --fork-point --onto B... B
test_rebase_same_head success noop same success work diff --fork-point --onto master... master
test_rebase_same_head success noop same success work diff --fork-point --keep-base master

test_done
