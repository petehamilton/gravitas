chai = require 'chai'
{ expect } = chai
chai.should()

{ scale, normed, normal, diff, cross, sect, makeSegment, makeSegmentBetween } = require './intersect'


describe "Intersection", ->
  describe "#makeSegment()", ->
    it "compies with makeSegmentBetween", ->
      makeSegment(-1, 1, 2, -3).should.deep.equal makeSegmentBetween(-1, 1, 1, -2)


  describe "#sect()", ->
    it "intersects simple coords", ->
      sect(
        makeSegment(-1, 0, 2, 0),  # -
        makeSegment(0, -1, 0, 2),  # |
      ).should.deep.equal
        x: 0
        y: 0

    it "doesn't intersect things that don't intersect", ->
      expect(sect(
        makeSegment(-1, 0, 2, 0),  # -
        makeSegment(2, -1, 0, 2),  # | too far right
      )).to.be.null

      expect(sect(
        makeSegment(-1, 2, 2, 0),  # - too far up
        makeSegment(0, -1, 0, 2),  # |
      )).to.be.null
