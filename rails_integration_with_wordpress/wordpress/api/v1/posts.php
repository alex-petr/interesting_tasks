<?php

require_once('api.php');

/**
 * Posts API class. Provide different actions with posts.
 *
 * @author Alexander Petrov <petrov@wearepush.co>
 * @project ShopSmart Blog
 * @date 24/05/16 13:33
 * @link http://wearepush.co/
 * @copyright Copyright © 2016 Alexander Petrov
 */
final class Posts extends API
{

    /**
     * Fetch posts from DB.
     *
     * @return array
     */
    public static function index()
    {
        $result = array('success' => false, 'message' => 'Error during posts selection from the DB.', 'data' => null);

        $count = isset($_GET['count']) ? $_GET['count'] : 10;

        if (isset($_GET['source']) && 'pokemon-go' == $_GET['source']) {
            if ('blog.shopsmart.co.id' == $_SERVER['SERVER_NAME']) {
                $posts_db = get_posts(array('posts_per_page' => $count, 'tag' => 'pokemon-go'));
            } else { // 'blog.shopsmart.xyz' == $_SERVER['SERVER_NAME']
                $posts_db = get_posts(array('posts_per_page' => $count, 'category_name' => 'pokemon-go-category'));
            }
        } else {
            $posts_db = get_posts(array('posts_per_page' => $count));
        }

        if (!empty($posts_db)) {
            $result['message'] = 'Posts are selected from the DB successfully.';
            $result['success'] = true;
            foreach ($posts_db as $post_db) {
                $result['data'][] = array(
                    'id'          => $post_db->ID,
                    'title'       => $post_db->post_title,
                    'description' => trim(strip_shortcodes(strip_tags(preg_split('/<!--more(.*?)?-->/',
                                         $post_db->post_content)[0])), " \t\n\r\0\x0B&nbsp;"),
                    'image'       => wp_get_attachment_url(get_post_meta($post_db->ID, '_thumbnail_id', true)),
                    'link'        => get_permalink($post_db->ID)
                );
            }
        }
        return $result;
    }

}

$response = array('status' => STATUS_UNAUTHORIZED, 'data' => null);

if (isset($_GET['secret']) && Posts::is_valid_secret($_GET['secret'])) {
    $posts = Posts::index();
    if ($posts['success']) {
        Posts::info($posts['message']);
        $response = array(
            'status' => STATUS_OK,
            'data'   => array(
                'success' => true,
                'messages' => array(
                    'success' => array($posts['message']),
                ),
                'posts' => $posts['data']
            )
        );
    } else {
        Posts::fatal($posts['message']);
        $response = array(
            'status' => STATUS_INTERNAL_SERVER_ERROR,
            'data'   => array(
                'messages' => array(
                    'error' => array($posts['message']),
                )
            )
        );
    }
} else {
    $message = 'Invalid secret key.';
    Posts::warn($message);
    $response['data'] = array('messages' => array('error' => array($message)));
}

Posts::send_response($response['status'], $response['data']);
