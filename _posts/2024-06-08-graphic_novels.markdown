---
layout: post
title:  "Graphic novels from the Mountain View public library"
date:   2024-06-08
categories: 读书
featured: false
draft: true
---

<h3>Can't we talk about something more pleasant?</h3>

> Roz Chast and her parents were practitioners of denial: if you don't ever think about death, it will never happen. 
Can't We Talk About Something More Pleasant? is the story of an only child watching her parents age well into their nineties and die. 
In this account, longtime New Yorker cartoonist Chast combines drawings with family photos and documents, chronicling that "long good-bye."

<div class="carousel-container">
    <button class="carousel-button prev" onclick="moveSlide(-1)">&#10094;</button>
    <div class="carousel-slides">
        <img src="/image/graphic_1.jpg" alt="Image 1">
        <img src="/image/graphic_2.jpg" alt="Image 2">
        <img src="/image/graphic_3.jpg" alt="Image 3">
        <img src="/image/graphic_4.jpg" alt="Image 4">
        <img src="/image/graphic_5.jpg" alt="Image 5">
        <img src="/image/graphic_6.jpg" alt="Image 6">
        <img src="/image/graphic_7.jpg" alt="Image 7">
        <img src="/image/graphic_8.jpg" alt="Image 8">
        <img src="/image/graphic_9.jpg" alt="Image 9">
        <img src="/image/graphic_10.jpg" alt="Image 10">
        <img src="/image/graphic_11.jpg" alt="Image 11">
        <img src="/image/graphic_12.jpg" alt="Image 12">
        <img src="/image/graphic_13.jpg" alt="Image 13">
        <!-- Add more images as needed -->
    </div>
    <button class="carousel-button next" onclick="moveSlide(1)">&#10095;</button>
    <div class="image-index">1/13</div>
</div>

<div class="carousel-container">
    <button class="carousel-button prev" onclick="moveSlide(-1)">&#10094;</button>
    <div class="carousel-slides">
        <img src="/image/graphic_14.jpg" alt="Image 14">
        <img src="/image/graphic_15.jpg" alt="Image 15">
        <img src="/image/graphic_16.jpg" alt="Image 16">
        <img src="/image/graphic_17.jpg" alt="Image 17">
        <!-- Add more images as needed -->
    </div>
    <button class="carousel-button next" onclick="moveSlide(1)">&#10095;</button>
    <div class="image-index">1/4</div>
</div>

<script>
let currentIndex = 0;

function moveSlide(direction) {
  const carousel = document.querySelector('.carousel-slides');
  const images = carousel.querySelectorAll('img');
  const totalImages = images.length;

  currentIndex += direction;

  // Handle reaching the end or beginning
  if (currentIndex >= totalImages) {
    currentIndex = 0;
  } else if (currentIndex < 0) {
    currentIndex = totalImages - 1;
  }

  // Move the carousel
  carousel.style.transform = `translateX(${-currentIndex * 100}%)`;

  // Update image index text
  document.querySelector('.image-index').textContent = `${currentIndex + 1}/${totalImages}`;
}

document.addEventListener("DOMContentLoaded", function() {
  // Set initial state
  const images = document.querySelectorAll('.carousel-slides img');
  const totalImages = images.length;
  document.querySelector('.image-index').textContent = `1/${totalImages}`;
});
</script>