package dungeons;

/**
 * Helper class to deal with eight2empire wall assets
 **/
class Eight2Empire
{
    private static var transitionTiles:IntHash<Int>;

    public static function getTileNumber(transition:Int):Int
    {
        var tiles:IntHash<Int> = getTransitionTiles();
        if (!tiles.exists(transition))
            transition &= 15;
        return tiles.get(transition);
    }

    private static function getTransitionTiles():IntHash<Int>
    {
        if (transitionTiles == null)
        {
            transitionTiles = new IntHash();

            transitionTiles.set(0, 20);
            transitionTiles.set(1, 13);
            transitionTiles.set(2, 14);
            transitionTiles.set(3, 10);
            transitionTiles.set(4, 12);
            transitionTiles.set(5, 4);
            transitionTiles.set(6, 16);
            transitionTiles.set(7, 3);
            transitionTiles.set(8, 15);
            transitionTiles.set(9, 11);
            transitionTiles.set(10, 1);
            transitionTiles.set(11, 1);
            transitionTiles.set(12, 17);
            transitionTiles.set(13, 2);
            transitionTiles.set(14, 0);
            transitionTiles.set(15, 0);

            transitionTiles.set(19, 10);
            transitionTiles.set(131, 10);
            transitionTiles.set(147, 10);
            transitionTiles.set(227, 10);
            transitionTiles.set(243, 10);
            transitionTiles.set(51, 10);
            transitionTiles.set(35, 10);

            transitionTiles.set(137, 11);
            transitionTiles.set(153, 11);
            transitionTiles.set(201, 11);
            transitionTiles.set(217, 11);
            transitionTiles.set(233, 11);
            transitionTiles.set(249, 11);

            transitionTiles.set(63, 7);
            transitionTiles.set(46, 7);
            transitionTiles.set(174, 7);
            transitionTiles.set(175, 7);
            transitionTiles.set(190, 7);
            transitionTiles.set(191, 7);
            transitionTiles.set(62, 7);
            transitionTiles.set(47, 7);

            transitionTiles.set(76, 17);
            transitionTiles.set(108, 17);
            transitionTiles.set(204, 17);
            transitionTiles.set(124, 17);
            transitionTiles.set(220, 17);
            transitionTiles.set(92, 17);
            transitionTiles.set(236, 17);
            transitionTiles.set(252, 17);

            transitionTiles.set(39, 3);
            transitionTiles.set(103, 3);
            transitionTiles.set(231, 3);
            transitionTiles.set(55, 3);
            transitionTiles.set(183, 3);
            transitionTiles.set(119, 3);
            transitionTiles.set(167, 3);
            transitionTiles.set(247, 3);

            transitionTiles.set(78, 6);
            transitionTiles.set(206, 6);
            transitionTiles.set(222, 6);
            transitionTiles.set(223, 6);
            transitionTiles.set(94, 6);
            transitionTiles.set(95, 6);
            transitionTiles.set(79, 6);
            transitionTiles.set(207, 6);

            transitionTiles.set(26, 1);
            transitionTiles.set(27, 1);
            transitionTiles.set(42, 1);
            transitionTiles.set(106, 1);
            transitionTiles.set(123, 1);
            transitionTiles.set(138, 1);
            transitionTiles.set(139, 1);
            transitionTiles.set(155, 1);
            transitionTiles.set(171, 1);
            transitionTiles.set(187, 1);
            transitionTiles.set(203, 1);
            transitionTiles.set(219, 1);
            transitionTiles.set(235, 1);
            transitionTiles.set(251, 1);

            transitionTiles.set(159, 5);
            transitionTiles.set(143, 5);

            transitionTiles.set(38, 16);
            transitionTiles.set(102, 16);
            transitionTiles.set(54, 16);
            transitionTiles.set(118, 16);
            transitionTiles.set(246, 16);
            transitionTiles.set(230, 16);

            transitionTiles.set(125, 2);
            transitionTiles.set(221, 2);
            transitionTiles.set(93, 2);
            transitionTiles.set(205, 2);
            transitionTiles.set(237, 2);
            transitionTiles.set(253, 2);
            transitionTiles.set(109, 2);
            transitionTiles.set(77, 2);

            transitionTiles.set(64, 20);
            transitionTiles.set(80, 20);
            transitionTiles.set(90, 20);
            transitionTiles.set(160, 20);
            transitionTiles.set(176, 20);
            transitionTiles.set(224, 20);
            transitionTiles.set(240, 20);


            transitionTiles.set(30, 0);
            transitionTiles.set(110, 0);
            transitionTiles.set(111, 0);
            transitionTiles.set(126, 0);
            transitionTiles.set(127, 0);
            transitionTiles.set(238, 0);
            transitionTiles.set(239, 0);
            transitionTiles.set(254, 0);
            transitionTiles.set(255, 0);
        }
        return transitionTiles;
    }
}
