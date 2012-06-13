if module?
  chai = require 'chai'
  intersect = require './intersect'
else
  { chai, intersect } = window


{ expect } = chai
chai.should()


{ sect, makeSegment, makeSegmentBetween } = intersect


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
        intersects: true
        point:
          x: 0
          y: 0

    it "doesn't intersect things that don't intersect", ->

      sect(
        makeSegment(-1, 0, 2, 0),  # -
        makeSegment(2, -1, 0, 2),  # | too far right
      ).should.deep.equal
        intersects: false
        point:
          x: 2
          y: 0

      sect(
        makeSegment(-1, 2, 2, 0),  # - too far up
        makeSegment(0, -1, 0, 2),  # |
      ).should.deep.equal
        intersects: false
        point:
          x: 0
          y: 2
